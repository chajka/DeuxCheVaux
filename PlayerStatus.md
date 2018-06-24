# Class PlayerStatus

Easy to access NicoLive information from API getplayerstatus

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
### title
Title of program
### desc
User defined description of program
### socialType
Type of streaming which one of community, channel, official
### community
Community number of this program
### isOwner
I’m owner flag of this program
### ownerIdentifier
Owner ID of this program
### ownerName
Owner nickname of this program
### baseTime
Base time for calcurate VPOS
### listenerIdentifier
Listener’s user ID
### listenerName
Listener’s user nickname
### listenerIsPremium
Listener’s user is premium flag
### listenerLanguage
Listener’s user using language
### listenerIsVIP
Listener’s user have VIP Pass flag
### messageServers
Known MessageServers of this program.