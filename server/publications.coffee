Meteor.publish "userData", ->
  if @userId
    return Meteor.users.find {_id: @userId}, {fields: {"admin":1, "email": 1, "services.github.email":1, "services.github.username": 1, "slotAssignments":1}}
  else
    @ready()

Meteor.publish "occasions", -> Occasions.find()
Meteor.publish "slots", -> Slots.find()
