import pytest
import requests


@pytest.fixture(scope="module")
def jenkins():
    import docker
    client = docker.from_env()

    # docker pull jenkins/jenkins:lts
    jenkins_image_present = len([x.tags for x in client.images.list() if 'jenkins/jenkins:lts' in x.tags]) > 0
    if not jenkins_image_present:
        client.images.pull('jenkins/jenkins:lts')

    # docker build -t jenkins .
    container_exists = len([
        x.tags for x in client.images.list()
        if 'pytest-jenkins:latest' in x.tags]
    ) > 0
    if container_exists:
        client.images.remove('pytest-jenkins:latest')
    # import pdb; pdb.set_trace()
    # if not container_exists:
    #     client.images.build(path='.', tag='pytest-jenkins')

    # docker run -p 8080:8080 -p 50000:50000 --env JAVA_OPTS="-Djenkins.install.runSetupWizard=false" jenkins &
    container = client.containers.run(
      'jenkins/jenkins:lts',
      environment={
          'JAVA_OPTS': '-Djenkins.install.runSetupWizard=false'
      },
      # name='pytest-jenkins',
      ports={'8080/tcp': 8080},
      detach=True
    )
    print('Waiting for Jenkins to come online')
    while True:
        if 'setting agent port for jnlp'.encode() in container.logs():
            break
            # yield container
    print('Jenkins is up and running.')

    yield container
    print('Stop Jenkins container.')
    container.stop()


def test_ehlo(jenkins):
    response = requests.get('http://localhost:8080')
    assert response.status_code == 200
