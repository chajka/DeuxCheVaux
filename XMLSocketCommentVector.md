#  Class XMLSocketCommentVector

Send and recieve comment by XML Socket

## Initialize

### Objective-C
InitWithProgram:cookies:

### Swift
init(playerStatus:PlayerStatus, serverOffset:Int, history:Int = defaultHistroryCount, cookies:Array<HTTPCookie>)

## Parameters
### playerStatus:`PlayerStatus`
player starus of want to fetch comment program number
### serverOffset:`Int`
Array offset of multi seat streaming
### history:`Int`
pre fetch comment count (default 400)
### cookies: `Array of NSHTTPCookie`
user_session cookie and more for emulate browser.

# Methods

##  open()
open stream socket and start recieve comment

## close()
close stream for end of reveive comment

## comment(comment:, command:)
post comment to this XMLSocket
### comment:`String`
text of comment to post
### command:`Array of String`
- anonymous comment (=184)
- comment position (ue or shita default is Normal)
- comment size (big or small default is regular)
- comment color (white, green, yellow, cyan, red, purple, blue, black, pink, orange for common and premium can specify optional color niconicowhite, truered, passionorange, elementalgreen, madyellow, marineblue and noblevilet)

## heartbeat(heartbeatCallback)
get heartbeat current status
### heartbeatCallback
closure of (watcherCount:`Int`, commentCount:`int`, token:`String`)

