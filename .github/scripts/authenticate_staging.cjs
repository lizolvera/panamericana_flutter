// Fixture de autenticación solo para staging. No cambia el backend ni envía correo.
const {randomInt} = require('node:crypto');
const fs = require('node:fs');
const {spawnSync} = require('node:child_process');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

function configuration(env) {
  const base = env.STAGING_API_URL || 'https://prybina-staging.onrender.com';
  if (base !== 'https://prybina-staging.onrender.com') throw Error('API fuera de staging');
  const uri = new URL(env.STAGING_MONGO_URI || '');
  if (uri.protocol !== 'mongodb+srv:' || uri.hostname !== 'panamericana-staging.ut6jhat.mongodb.net' ||
      uri.pathname !== '/panamericana_staging') throw Error('Base fuera de staging');
  if (!env.STAGING_TEST_PASSWORD || env.STAGING_TEST_PASSWORD.length < 12) throw Error('Falta contraseña de fixture');
  return {base, uri: uri.toString(), password: env.STAGING_TEST_PASSWORD};
}

async function authenticate(env=process.env) {
  const cfg=configuration(env), tokens={};
  await mongoose.connect(cfg.uri,{dbName:'panamericana_staging',serverSelectionTimeoutMS:15000});
  const users=mongoose.connection.collection('usuarios');
  try {
    for (const letter of ['a','b']) {
      const email=`cliente.${letter}@example.test`, user=await users.findOne({email,rol:'usuario'});
      if (!user || !await bcrypt.compare(cfg.password,user.password)) throw Error('Fixture no válida');
      const code=String(randomInt(100000,1000000));
      // Solo las cuentas sintéticas exactas reciben códigos temporales sin correo.
      await users.updateOne({_id:user._id,email,rol:'usuario'},{$set:{loginCode:code,loginCodeExpires:new Date(Date.now()+120000)}});
      try {
        const res=await fetch(cfg.base+'/api/usuarios/verify-2fa',{
          method:'POST',redirect:'error',signal:AbortSignal.timeout(90000),
          headers:{'Content-Type':'application/json'},body:JSON.stringify({email,code})
        });
        if (!res.ok) throw Error('Verificación de código rechazada');
        const result=await res.json();
        if (result.rol!=='usuario' || !/^[\w-]+\.[\w-]+\.[\w-]+$/.test(result.token||'')) throw Error('Sesión no válida');
        tokens[`STAGING_CLIENT_${letter.toUpperCase()}_TOKEN`]=result.token;
        const fresh=await users.findOne({_id:user._id});
        if (!fresh.activeTokens?.includes(result.token)) throw Error('Sesión no registrada');
      } finally {
        await users.updateOne({_id:user._id,loginCode:code},{$unset:{loginCode:'',loginCodeExpires:''}});
      }
    }
    if(env.GITHUB_ACTIONS==='true') {
      if(!env.GITHUB_ENV)throw Error('Falta archivo de entorno');
      for(const [key,token] of Object.entries(tokens)) {
        console.log(`::add-mask::${token}`);
        fs.appendFileSync(env.GITHUB_ENV,`${key}=${token}\n`);
      }
    }
    return tokens;
  } catch(error) {
    for(const [key,token] of Object.entries(tokens)) {
      const letter=key.includes('_A_')?'a':'b';
      await users.updateOne({email:`cliente.${letter}@example.test`,rol:'usuario'},{$pull:{activeTokens:token}});
    }
    throw error;
  } finally {await mongoose.disconnect();}
}

async function revoke(env=process.env) {
  const cfg=configuration(env);
  await mongoose.connect(cfg.uri,{dbName:'panamericana_staging',serverSelectionTimeoutMS:15000});
  try {
    for(const letter of ['a','b']) {
      const token=env[`STAGING_CLIENT_${letter.toUpperCase()}_TOKEN`];
      if(token)await mongoose.connection.collection('usuarios').updateOne(
        {email:`cliente.${letter}@example.test`,rol:'usuario'},{$pull:{activeTokens:token}});
    }
  } finally {await mongoose.disconnect();}
}

if(require.main===module) (async()=>{
  if(process.argv.includes('--revoke')) {await revoke();console.log('Sesiones de la ejecución revocadas.');return;}
  const tokens=await authenticate();
  console.log('Dos sesiones sintéticas verificadas; no se enviaron correos.');
  if(process.argv.includes('--check-contract')) {
    try {
      const r=spawnSync(process.env.PYTHON_BIN||'python3',['.github/scripts/staging_api.py'],
        {env:{...process.env,...tokens},stdio:'inherit'});
      if(r.error||r.status!==0)throw Error('Contrato API no aprobado');
    } finally {await revoke({...process.env,...tokens});}
  }
})().catch(()=>{console.error('Autenticación de staging fallida; revisar secretos, fixture y conectividad.');process.exitCode=1;});
module.exports={configuration,authenticate,revoke};
