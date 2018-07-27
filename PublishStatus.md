#  Class PublishStatus

Easy to access NicoLive information from API getpublishstatus

## Initialize

### Objective-C
InitWithProgram:cookies:

### Swift
PlayerStatus(program: , cookies: )

## Parameters
### Program:String
lv number string of program want to get streaming info
### cookies: Array of NSHTTPCookie
user_session cookie and more for emulate browser.
## Properties
### number
lv number of program
### token
owner token of program
### canVote
this program can vote (Bool)
### rtmpURL
rtmp url for send video
### streamKey
rtmp stream key for send video
