" Vim syntax file
" Language:     Squish Ruby Test
" Maintainer:   anon
" Date:         2026-08-26

" Reference used: https://doc.qt.io/squish/squish-api.html

if exists("b:current_syntax")
  finish
endif

runtime! syntax/ruby.vim
unlet b:current_syntax

syntax keyword squishObject
    \ ApplicationContext
    \ Image
    \ RemoteSystem
    \ Screen
    \ TopLevelWindow
    \ UiTypes
    \ objectMap
    \ squishinfo
    \ testData
    \ testInteraction
    \ testSettings

syntax keyword squishFunction
    \ add
    \ applicationContext
    \ applicationContextList
    \ attachFile
    \ attachImage
    \ attachToApplication
    \ breakpoint
    \ cast
    \ children
    \ className
    \ className
    \ compare
    \ compareJSONFiles
    \ compareTextFiles
    \ compareXMLFiles
    \ convertTo
    \ create
    \ createNull
    \ createVisualVP
    \ currentApplicationContext
    \ dataset
    \ datasetExcel
    \ defaultApplicationContext
    \ doubleClick
    \ endSection
    \ exception
    \ exists
    \ exists
    \ fail
    \ fatal
    \ field
    \ fieldNames
    \ findAllObjects
    \ findAllOcrText
    \ findFile
    \ findImage
    \ findObject
    \ findOcrText
    \ get
    \ getClipboardText
    \ getOcrText
    \ globalBounds
    \ grabScreenshot
    \ grabWidget
    \ highlightObject
    \ imagePresent
    \ isNull
    \ keyPress
    \ keyRelease
    \ load
    \ log
    \ mouseClick
    \ mouseMove
    \ mousePress
    \ mouseRelease
    \ nativeMouseClick
    \ nativeType
    \ ocrTextPresent
    \ parent
    \ pass
    \ properties
    \ put
    \ realName
    \ remove
    \ resultCount
    \ saveDesktopScreenshot
    \ saveObjectSnapshot
    \ sendNativeEvent
    \ setApplicationContext
    \ setClipboardText
    \ skip
    \ snooze
    \ source
    \ stackTrace
    \ startApplication
    \ startSection
    \ startVideoCapture
    \ stopVideoCapture
    \ symbolicName
    \ symbolicNames
    \ tapObject
    \ topLevelObjects
    \ touchAndDrag
    \ touchMove
    \ touchPress
    \ touchRelease
    \ typeName
    \ verify
    \ vp
    \ vpWithImage
    \ vpWithObject
    \ waitFor
    \ waitForApplicationLaunch
    \ waitForImage
    \ waitForObject
    \ waitForObjectExists
    \ waitForObjectItem
    \ waitForOcrText
    \ warning
    \ xcompare
    \ xfail
    \ xpass
    \ xverify
    \ xvp


" ---

highlight default link squishObject   Identifier
highlight default link squishFunction Function

let b:current_syntax = "squishrubytest"
