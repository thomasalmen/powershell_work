#Textbelt sms OTP
$body = @{
  "phone"="+46709566669"
  "message"="Hello World"
  #"key"="cbc057809fb1a71588e91914f41bac79ffeb8d905ZE24CnFF8VWTlae9iyMZLnEO"
}
$submit = Invoke-WebRequest -Uri https://textbelt.com/text -Body $body -Method Post
