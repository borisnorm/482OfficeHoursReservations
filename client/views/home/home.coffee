Router.route "/", ->
  @layout "ApplicationLayout"
  @render "Home"

Template.Home.helpers
  currentUserHasEmail: -> Meteor.user()?.services?.github?.email || Meteor.user()?.email

Template.Home.events
  "click #signup-button": ->
    Meteor.loginWithGithub()
    return false

Template.EnterEmail.events
  "submit .email-correction": ->
    email = $("#emailPicker").val()
    console.log "Registering email #{email}"
    Meteor.call("provideEmailAddress",email)
    return false
  "keypress, changed .emailBox": ->
    formDep.changed()

formDep = new Deps.Dependency

Template.EnterEmail.helpers
  emailsDontMatch: ->
    formDep.depend()
    email = $("#emailPicker").val()
    verifyEmail = $("#emailVerifier").val()
    return email != verifyEmail or not email
