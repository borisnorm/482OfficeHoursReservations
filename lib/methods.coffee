Meteor.methods
  addOccasion: (startDate, duration, location, instructor) ->
    throw new Meteor.Error("not-authorized") unless Meteor.user()?.admin
    Occasions.insert
      startDate: startDate
      duration: duration
      location: location
      instructor: instructor
      slotsAssigned: false
      waitlist: []
      creator: Meteor.userId()
    , (err, occasionId) ->
      for slot in [0...duration*6] #ten minute slots
        Slots.insert
          occasion: occasionId
          startTime: new Date(startDate.valueOf() + slot*600000)
          selectedCandidate: null

  deleteOccasion: (occasionId) ->
    throw new Meteor.Error("not-authorized") unless Meteor.user()?.admin
    Occasions.remove
      _id: occasionId
    Slots.remove
      occasion: occasionId

  registerForOccasion: (occasionId) ->
    throw new Meteor.Error("not-authorized") unless Meteor.userId()
    occasion = Occasions.findOne _id: occasionId
    throw new Meteor.Error("already-assigned", "Slots were already assigned!") if occasion.slotsAssigned
    throw new Meteor.Error("already-waitlisted", "User already on waitlist") if _.contains occasion.waitlist, Meteor.userId()
    Occasions.update {_id: occasionId}, {$addToSet:{waitlist: Meteor.userId()}}

  deregisterForOccasion: (occasionId) ->
    throw new Meteor.Error("not-authorized") unless Meteor.userId()
    occasion = Occasions.findOne _id: occasionId
    throw new Meteor.Error("already-assigned", "Slots were already assigned!") if occasion.slotsAssigned
    throw new Meteor.Error("not-waitlisted", "User not on waitlist") unless _.contains occasion.waitlist, Meteor.userId()
    Occasions.update {_id: occasionId}, {$pull: {waitlist:Meteor.userId()}}

  provideEmailAddress: (email) ->
    throw new Meteor.Error("not-authorized") unless Meteor.userId()
    numUpdated = Meteor.users.update {"_id": Meteor.userId(),"services.github.email": "", email:{$exists:false}}, {$set: {"email": email}}
    unless numUpdated > 0
      throw new Meteor.Error("Invalid-update","Cannot update your user. You might already have an email?(#{Meteor.user().services?.github?.email})")
