Meteor.startup ->
  process.env.MAIL_URL = "smtp://EMAIL:KEY@smtp.mandrillapp.com:587/"
