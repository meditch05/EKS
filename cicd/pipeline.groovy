//================
// 변수처리 하려면 명령어를 "" 로 묶어야 한다. ''로 묶으면 PlainText 처리해버림
// env.GIT_CREDENTIAL	// ID/PWD
// env.GIT_URL			// http://gitlab.mwportal.com:8080/p069528/SpringBoot_JPA_OJT.git
// env.K8S_CLUSTER		// https://150.149.49.43:6443
// env.DOCKER_REGISTRY	// myregistry.mwportal.com:30001
// env.DOCKER_PKG		// mwportal/tps-res
// env.DOCKER_TAG		// 1.0 ( DockerImageURL = myregistry.mwportal.com:30001/ojt/springboot_jpa_ojt:1.0 )

def label    = "jenkins-slave-jnlp-${UUID.randomUUID().toString()}"
def imagetag = env.DOCKER_REGISTRY + "/" + env.DOCKER_PKG + ":" + env.DOCKER_TAG
// def src_dir  = env.SRC_ROOT

podTemplate(label: label, cloud: 'kubernetes', serviceAccount: 'jenkins',
	containers: [
        
        containerTemplate(name: 'jnlp', image: 'jenkins/jnlp-slave:3.27-1', args: '${computer.jnlpmac} ${computer.name}',
            envVars: [
                envVar(key: 'JVM_HEAP_MIN', value: '-Xmx192m'),
                envVar(key: 'JVM_HEAP_MAX', value: '-Xmx192m')
            ]
        ),
        containerTemplate(name: 'maven',    image: 'maven:3.6.1-jdk-8-alpine',			ttyEnabled: true, command: 'cat'),
		containerTemplate(name: 'docker',   image: 'docker:18.06',                      ttyEnabled: true, command: 'cat', resourceLimitMemory: '128Mi'),
        containerTemplate(name: 'kubectl',  image: 'lachlanevenson/k8s-kubectl:latest', ttyEnabled: true, command: 'cat', resourceLimitMemory: '256Mi')
    ],
    volumes:[
        hostPathVolume(mountPath: '/var/run/docker.sock',   hostPath: '/var/run/docker.sock'),
        hostPathVolume(mountPath: '/etc/hosts',             hostPath: '/etc/hosts'),
		persistentVolumeClaim(mountPath: '/home/jenkins/workspace', claimName: 'jenkins-workspace'),
		persistentVolumeClaim(mountPath: '/root/.m2',               claimName: 'jenkins-maven-repo')
    ])
{
	node(label) {			stage('CheckOut Source') { // gitLab API Plugin, gitLab Plugin
			git branch: "master", credentialsId: env.GIT_CREDENTIAL, url: env.GIT_URL
		}
		stage('Build Maven') {  // Maven Integration:3.3
			container('maven') {
			    sh "mvn clean"
			    // sh "wget https://maven.xwiki.org/externals/com/oracle/jdbc/ojdbc8/12.2.0.1/ojdbc8-12.2.0.1.jar"
			    // sh 'mvn install:install-file -Dfile="ojdbc8-12.2.0.1.jar" -DgroupId=com.oracle -DartifactId=ojdbc8 -Dversion=12.2.0.1 -Dpackaging=jar'
				sh "mvn -f ./pom.xml -B -DskipTests package" // clean package
				sh "cp ./target/app-1.0.war ."
			}				}
			stage('Build Docker Image') {
			container('docker') {
				sh "docker build -t ${imagetag} -f ./docker/Dockerfile ."
			}
		}
			stage('Push Docker Image') {
			container('docker') {
				sh "docker push ${imagetag}"
			}
		}
			stage('k8s Update Deployment Image = ${imagetag}') {
			container('kubectl') {
		                sh "kubectl delete -f ./kubernetes/deployment.yaml"
				sh "kubectl apply -f  ./kubernetes/deployment.yaml"
				sh "kubectl get deploy,pod -n mwportal -l app=swing-tps-res"
							// sh "kubectl apply -f ./kubernetes/service.yaml"  // service.yaml 은 초기 테스트시에 구성해야함 ( 그래야지 ㅡ_ㅡ )
				// sh "kubectl apply -f ./kubernetes/ingress.yaml"  // ingress.yaml 은 초기 테스트시에 구성해야함 ( 그래야지 ㅡ_ㅡ )
			}
		}
		}
}
//================
