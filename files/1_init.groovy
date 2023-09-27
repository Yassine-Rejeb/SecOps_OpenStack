import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

// Initializations and objects creation
def installed = false
def initialized = false

jenkins_plugins="ant" // build-timeout credentials-binding email-ext gradle workflow-aggregator ssh-slaves subversion timestamper ws-cleanup matrix-auth"

def pluginParameter="${jenkins_plugins}"
def plugins = pluginParameter.split()

def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()


// Create a new security realm with the admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
//hudsonRealm.createAccount("admin", "admin123")

// Set the security realm and authorization strategy for the instance
instance.setSecurityRealm(hudsonRealm)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

//Install plugins
plugins.each {
  if (!pm.getPlugin(it)) {
    if (!initialized) {
      uc.updateAllSites()
      initialized = true
    }
    def plugin = uc.getPlugin(it)
    if (plugin) {
    	def installFuture = plugin.deploy()
      while(!installFuture.isDone()) {
        sleep(3000)
      }
      installed = true
    }
  }
}
if (installed) {
  instance.save()
  instance.restart()
}

//def jenkinsUrl = "http://54.172.214.153:8080"
