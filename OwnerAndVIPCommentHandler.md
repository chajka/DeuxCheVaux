#  Class OwnerAndVIPCommentHandler

handling operator command and post owner or vip comment.

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
# Methods

##  startStreaming
start current testing stream

## stopStreaming
end current testing or broadcasting stream

## postOwnerComment `(throws)`
post owner comment
### comment:`String`
comment to post  
### name:`String`
name of comment poster (optional)  
### color:`String`
color of comment (optional)
### isPerm:`Bool`
flag for comment is parmanent display (optional)
### throw
`CommentPostError.EmptyComment` if coment is empty string

## clearOwnerComment
clear parmanent comment

## postVIPComment `(throws)`
post VIP(=BSP) comment with name and specified color
### comment:`String`
comment to post
### name:`String`
name of comment poster
### color:`String`
color of comment poster name
usable color is `white`, `red`, `green`, `blue`, `cyan`, `yellow`, `purple`, `pink`, `orange` and `niconicowhite`
### throw
`CommentPostError.EmptyComment` if coment is empty string
`CommentPostError.NameUndefined` if comment poster name is empty string
`CommentPostError.InvalidColor(String)` if coment can not accept

