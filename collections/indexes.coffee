if Meteor.isServer
    Meteor.startup ->
        Slots._ensureIndex "occasion": 1
        Occasions._ensureIndex "startDate":1
        Occasions._ensureIndex "slotsAssigned": 1
    