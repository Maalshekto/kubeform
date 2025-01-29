[http.routers]
  [http.routers.jenkins]
    rule = "PathPrefix(\`/jenkins\`)"
    entryPoints = ["web"]
    service = "jenkins"

[http.services]

%{ for k, cluster in clusters }
[http.services.jenkins-${cluster.name}.loadBalancer]
  [[http.services.jenkins-${cluster.name}.loadBalancer.servers]]
    url = "http://${controlplane_ips[k]}:30080"
%{ endfor }

[http.services.jenkins.weighted]
  services = [
%{ for k, cluster in clusters }
    { name = "jenkins-${cluster.name}", weight = ${weights[cluster.name]} },
%{ endfor }
  ]