Meteor.methods
  assignSlots: ->
    throw new Meteor.Error("not-authorized") unless Meteor.user()?.admin
    checkOccasionDeadlines(true)

deadlineIntervalID = 0
setDeadlineInterval = -> deadlineIntervalID = Meteor.setInterval checkOccasionDeadlines, 200000
Meteor.startup -> setDeadlineInterval()

checkOccasionDeadlines = (force = false) ->
  Meteor.clearInterval deadlineIntervalID
  queryParams =
    slotsAssigned:false
  unless force
    queryParams["startDate"] = $lte: new Date((new Date).valueOf() + 60000*60)
  occasionsDue = Occasions.find queryParams
  occasionsDue.forEach (occasion) ->
    Occasions.update {_id: occasion._id}, {$set: {slotsAssigned: true}}
    occasionSlots = Slots.find {occasion: occasion._id}, {sort:{startTime:1}}
    assignSlotSync = Meteor.wrapAsync(assignSlot)
    occasionSlots.forEach (slot) -> assignSlotSync slot
    updatedOccasion = Occasions.findOne {_id: occasion._id}
    for loser in updatedOccasion.waitlist
      sendLoserEmail(loser, updatedOccasion)
  setDeadlineInterval()
  console.log "Checked occasion deadlines!"

assignSlot = (slot, cb) ->
  occasion = Occasions.findOne _id: slot.occasion
  return cb(null) unless occasion.waitlist.length

  candidateCursor = Meteor.users.find _id: {$in: occasion.waitlist}
  candidatePairs = candidateCursor.map (candidate) ->
    numSlots = if candidate.slotAssignments then candidate.slotAssignments.length else 0
    return [candidate._id,numSlots]
  candidatePriorityObject = _.object candidatePairs
  minPriority = Math.min.apply(Math, _.values(candidatePriorityObject))
  console.log "Candidates are"
  console.log candidatePairs
  matchingPairs = _.filter candidatePairs, (pair) -> pair[1] == minPriority
  console.log "Matching pairs are"
  console.log matchingPairs
  winningPair = _.sample matchingPairs
  Meteor.users.update {_id: winningPair[0]}, {$addToSet: {slotAssignments: slot._id}}, (err, numAffected) ->
    cb(err) if err
    candidate = Meteor.users.findOne {_id : winningPair[0]}
    candidateName = getCandidateName(candidate)
    candidateEmail = candidate?.services?.github?.email || candidate?.email
    Slots.update {_id: slot._id}, {$set:{selectedCandidate: candidateName}}, (err, numAffected) ->
      cb(err) if err
      sendSlotWinnerEmail(slot,candidateName,candidateEmail)
      Occasions.update {_id: slot.occasion}, {$pull: {waitlist: candidate._id}}, (err, numAffected) ->
        cb(err)

getCandidateName = (candidate) ->
  if candidate?.profile?.name then candidate?.profile?.name else candidate?.services?.github?.username

sendLoserEmail = (userID, occasion) ->
  loser = Meteor.users.findOne _id: userID
  candidateEmail = loser?.services?.github?.email || loser?.email
  candidateName = getCandidateName(loser)
  sendOccasionLoserEmail(occasion,candidateName,candidateEmail) if candidateEmail
  console.log "Couldn't email #{candidateName}, email not found!" unless candidateEmail

sendSlotWinnerEmail = (slot, candidateName, candidateEmail) ->
  slotStartString = moment(slot.startTime).calendar()
  slotStartString = slotStartString.charAt(0).toLowerCase() + slotStartString.substring(1)
  occasion = Occasions.findOne(_id: slot.occasion)
  instructorString = occasion.instructor || "an instructor"
  locationString = occasion.location || "the usual location (check CTools)"
  emailHTML = "Hi there, <b>#{candidateName}!</b> <br> It's your lucky day!
  You must attend your 10 minute office hours slot #{slotStartString} with #{instructorString} at #{locationString}.
  <br> See you soon!"
  sendEmail(candidateEmail,"You were assigned a 482 office hours slot",emailHTML)

sendOccasionLoserEmail = (occasion, candidateName, candidateEmail) ->
  slotStartString = moment(occasion.startDate).calendar()
  slotStartString = slotStartString.charAt(0).toLowerCase() + slotStartString.substring(1)
  instructorString = occasion.instructor || "an instructor"
  locationString = occasion.location || "the usual location (check CTools)"
  emailHTML = "Hi <b>#{candidateName}!</b> <br>
  Unfortunately, you weren't assigned an office hours slot at #{slotStartString} with #{instructorString} at #{locationString}.
  Try again next time - those with less office hours assigned get precedence over those with more!"
  sendEmail(candidateEmail, "You weren't assigned a 482 office hours slot", emailHTML)

sendEmail = (recipientAddress, subject, htmlContent) ->
  emailObject = {}
  emailObject["from"] = "482 Reservations <482reservations@michaelschmatz.com>"
  emailObject["to"] = recipientAddress
  emailObject["subject"] = subject
  emailObject["html"] = htmlContent
  Email.send(emailObject)
  console.log "Send email to #{recipientAddress}"
