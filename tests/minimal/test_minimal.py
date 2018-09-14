import pytest
import requests
import time
import os

EMPTY_PIPELINE_XML = '''<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.18">
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.47">
    <script>{}</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>'''


def timeit(method):
    def timed(*args, **kw):
        ts = time.time()
        result = method(*args, **kw)
        te = time.time()
        if 'log_time' in kw:
            name = kw.get('log_name', method.__name__.upper())
            kw['log_time'][name] = int((te - ts) * 1000)
        else:
            print(
                '%r  %2.2f ms' %
                (method.__name__, (te - ts) * 1000)
            )
        return result
    return timed


@timeit
def pull_jenkins_docker_image(client):
    # docker pull jenkins/jenkins:lts
    jenkins_image_present = len([
        x.tags for x in client.images.list()
        if 'jenkins/jenkins:lts' in x.tags
    ]) > 0
    if not jenkins_image_present:
        client.images.pull('jenkins/jenkins:lts')


@timeit
def build_jenkins_docker(client, reuse=True):
    # docker build -t jenkins .
    container_exists = len([
        x.tags for x in client.images.list()
        if 'pytest-jenkins:latest' in x.tags]
    ) > 0
    if container_exists and not reuse:
        client.images.remove('pytest-jenkins:latest')

    # import pdb; pdb.set_trace()
    if not container_exists:
        client.images.build(path='.', tag='pytest-jenkins')


@timeit
def run_jenkins_docker(client):
    # docker run -p 8080:8080 -p 50000:50000 --env JAVA_OPTS="-Djenkins.install.runSetupWizard=false" jenkins &
    container = client.containers.run(
        'pytest-jenkins:latest',
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
    return container


@pytest.fixture(scope="module")
def jenkins():
    import docker
    client = docker.from_env()

    # pull_jenkins_docker_image(client)

    # build_jenkins_docker(client)
    container = run_jenkins_docker(client)
    yield container
    print('Stop Jenkins container.')
    container.stop()


def test_ehlo(jenkins):
    response = requests.get('http://localhost:8080')
    assert response.status_code == 200


def test_can_create_pipeline_job(jenkins):
    import jenkins

    server = jenkins.Jenkins('http://localhost:8080')
    for job in server.get_jobs():
        server.delete_job(job.get('name'))

    current_dir = os.path.dirname(os.path.realpath(__file__))
    jenkins_job_file = os.path.join(current_dir, 'Jenkinsfile')
    jenkins_job = open(jenkins_job_file, 'r').read()
    server.create_job('test', EMPTY_PIPELINE_XML.format(jenkins_job))
    assert 'test' in [job.get('name') for job in server.get_jobs()]


def test_can_run_pipeline_job(jenkins):
    import jenkins

    server = jenkins.Jenkins('http://localhost:8080')
    for job in server.get_jobs():
        server.delete_job(job.get('name'))

    current_dir = os.path.dirname(os.path.realpath(__file__))
    jenkins_job_file = os.path.join(current_dir, 'Jenkinsfile')
    jenkins_job = open(jenkins_job_file, 'r').read()
    server.create_job('test', EMPTY_PIPELINE_XML.format(jenkins_job))
    server.build_job('test')
    # wait for build to complete
    while server.get_job_info('test').get('lastCompletedBuild') is None:
        print('.')
        time.sleep(1)
    jenkins_build_result = server.get_build_info('test', 1).get('result')
    if jenkins_build_result != 'SUCCESS':
        print(server.get_build_console_output('test', 1))
    assert 'SUCCESS' == server.get_build_info('test', 1).get('result')
