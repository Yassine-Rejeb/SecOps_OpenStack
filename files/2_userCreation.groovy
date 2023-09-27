import jenkins.model.*
import hudson.security.*

// Define a list of users to create
def users = [
  [username: 'M0D4S', password: 'M0D4S', fullName: 'John Doe', email: 'John@mail.me'],
]

// Loop through the list of users and create them
def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
for (user in users) {
  hudsonRealm.createAccount(user['username'], user['password'])
  def u = instance.getUser(user['username'])
  u.setFullName(user['fullName'])
  //u.setEmail(new hudson.tasks.Mailer.UserProperty(user['email']))
  u.save()
}
// Bypass the initial setup
def setupWizard = instance.getSetupWizard()
setupWizard.completeSetup()

