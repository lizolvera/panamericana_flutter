const {test}=require('node:test');
const assert=require('node:assert/strict');
const {configuration}=require('./authenticate_staging.cjs');
const valid={STAGING_API_URL:'https://prybina-staging.onrender.com',
  STAGING_MONGO_URI:'mongodb+srv://fixture:fixture@panamericana-staging.ut6jhat.mongodb.net/panamericana_staging',
  STAGING_TEST_PASSWORD:'password-for-test-only'};
test('solo acepta el origen y base de staging previstos',()=>{
  assert.equal(configuration(valid).base,valid.STAGING_API_URL);
  for(const url of ['https://prybinaback.onrender.com','https://prybina-staging.onrender.com.evil.test','http://prybina-staging.onrender.com',valid.STAGING_API_URL+'/api'])
    assert.throws(()=>configuration({...valid,STAGING_API_URL:url}));
  for(const uri of ['mongodb+srv://fixture:fixture@production.example/test',valid.STAGING_MONGO_URI.replace('/panamericana_staging','/test'),valid.STAGING_MONGO_URI.replace('mongodb+srv:','https:')])
    assert.throws(()=>configuration({...valid,STAGING_MONGO_URI:uri}));
});
test('rechaza contraseña ausente o demasiado corta',()=>{
  for(const p of ['',undefined,'short'])assert.throws(()=>configuration({...valid,STAGING_TEST_PASSWORD:p}));
});
