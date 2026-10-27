"""Rutas de promoción permitidas; no realiza operaciones Git."""
import os
import sys

def permitted(event, base, head, same_repository=True):
    if event != 'pull_request':
        return True
    if base == 'release':
        return same_repository and head == 'develop'
    if base == 'master':
        return same_repository and head == 'release'
    return True

if __name__ == '__main__':
    ok = permitted(os.getenv('EVENT_NAME'), os.getenv('BASE_BRANCH'),
                   os.getenv('HEAD_BRANCH'), os.getenv('SAME_REPOSITORY') == 'true')
    print('Ruta de ramas aprobada.' if ok else 'Promoción rechazada: usar develop → release → master dentro del repositorio.')
    sys.exit(0 if ok else 1)
