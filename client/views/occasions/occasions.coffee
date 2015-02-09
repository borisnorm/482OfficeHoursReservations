isAdminHelper = -> return Meteor.user()?.admin

Template.occasions.helpers
    isAdmin: isAdminHelper

    occasions: ->
        return Occasions.find()
    numOccasions: ->
        return Occasions.find().count()
Template.occasions.events
    "click #check-deadlines": ->
        Meteor.call "assignSlots"

Template.newOccasionForm.events
    "submit .new-event": (e) ->
        startDate = $('#startDatePicker').data("DateTimePicker").getDate().toDate()
        duration = $("#durationPicker").val()
        location = $("#locationPicker").val() || "the usual location (check CTools)"
        instructor = $("#instructorPicker").val() || "an instructor"
        Meteor.call "addOccasion", startDate, duration, location, instructor
        return false


timeDependency = new Deps.Dependency
updateTime = ->
    timeDependency.changed()
Meteor.setInterval(updateTime, 1000)

Template.newOccasionForm.rendered =  ->
    $('#startDatePicker').datetimepicker
        minuteStepping:1


Template.occasionPanel.helpers
    startString: ->
        return moment(@startDate).format("MMMM Do, h:mm a")
    registrationDeadlineString: ->
        timeDependency.depend()
        moment(@startDate.valueOf() - 60000*60).fromNow()
    registrationDeadlinePassed: ->
        timeDependency.depend()
        (@startDate.valueOf() - 60000*60) < (new Date()).valueOf() 
    endString: -> return moment(@endDate).calendar()
    isAdmin: isAdminHelper
    notAllowedToRegister: ->
      alreadyRegisteredForOneSlot = _.contains @waitlist, Meteor.userId()
      return (@startDate.valueOf() - 60000*60) < (new Date()).valueOf() or alreadyRegisteredForOneSlot or @slotsAssigned
    notAllowedToLeave: ->
      timeDependency.depend()
      return (@startDate.valueOf() - 60000*60) < (new Date()).valueOf() or @slotsAssigned
    waitListLength: -> @waitlist.length
    onWaitlist: -> _.contains @waitlist, Meteor.userId()

Template.slotTable.helpers
    slots: -> Slots.find {occasion: @_id}, {sort: {startTime: 1}}

Template.slotTableRow.helpers
    startString: -> moment(@startTime).format("h:mm")
    candidateSelected: ->
        unless @selectedCandidate
            return "First come, first serve"
        else
            return @selectedCandidate

Template.occasionPanel.events
    "click .occasion-delete": (e) ->
        Meteor.call("deleteOccasion", @_id)
        return false
    "click .join-waitlist-button": (e) ->
        Meteor.call "registerForOccasion", @_id
        return false
    "click .leave-waitlist-button": (e) ->
        Meteor.call "deregisterForOccasion", @_id
        return false
