Template.navbar.helpers
    usersName: -> Meteor.user()?.profile?.name || Meteor.user()?.services?.github?.username
    slotAssignments: -> Meteor.user()?.slotAssignments?.length || 0
    oneSlot: ->
      if Meteor.user()?.slotAssignments?.length
        return Meteor.user()?.slotAssignments?.length == 1
      return false

Template.navbar.events
    "click #loginLink": (e) ->
        Meteor.loginWithGithub()
        return false
    "click #logoutLink": (e) ->
        Meteor.logout()
        return false
