# Selection range helper function
setSelectionRange = ( inputElement, selectionStart, selectionEnd ) ->
  if inputElement.setSelectionRange
    inputElement.focus()
    inputElement.setSelectionRange selectionStart, selectionEnd
  else if inputElement.createTextRange
    range = inputElement.createTextRange()
    range.collapse true
    range.moveEnd 'character', selectionEnd
    range.moveStart 'character', selectionStart
    range.select()
    
# Scroll line number and source together
$( '#source' ).scroll ->
  $( '#source_line_numbers' ).scrollTop(
    $( '#source' ).scrollTop() )
  false

# Find the nearest variable assignment preceeding or at cursor position line
findVariableAssignment = ( cursorPosition, source ) ->
  # Find the end of the cursor position line
  endIndex = source.indexOf '\n', cursorPosition
  if endIndex is -1
    endIndex = source.length
  sourcePrior = source.substring 0, endIndex
  
  # Match the nearest variable assignment that is not a comment
  results = sourcePrior.match /\n[^\#]*\w+\s*=\s*\w+[^\/\[\(]/g
  if results is null
    return 0
  nearestResult = results[ results.length - 1]
  matches = nearestResult.match /(\w+)\s*=\s*(\w+)[^\/\[]/
  leftSideName = matches[ 1 ]
  rightSideName = matches[ 2 ]

  # We now have a left side and right side of assignment, find them in results
  compiledCode = $( '#results' ).text()
  # find position of function we are looking for
  pattern = leftSideName + "\\s=\\s" + rightSideName
  p = new RegExp( pattern, "g" );
  functionCode = compiledCode.match p
  compiledLocation = compiledCode.indexOf functionCode
  return compiledLocation

# Add line numbers to the source editor
# But return source without line numbers for compiling
lineNumbersAndCompileSource = ( compile = true ) ->
  testStringWidth = $( '#font_test' )[ 0 ].clientWidth
  charsInTest = $( '#font_test' )[ 0 ] 
  fontWidth = testStringWidth / 62
  # -5 is due to textarea left padding of 5px
  columnsPerLine = ( $( '#source' )[ 0 ].clientWidth - 5 ) / fontWidth
  columnsPerLine = parseInt columnsPerLine
  testStringHeight = $( '#font_test' )[ 0 ].clientHeight
  fontHeight = testStringHeight / 3
  
  originalSource = $( '#source' ).val()
  if originalSource.length is 0
    $( '.file_name' ).text ''
  source = originalSource.split( '\n' )
  totalLines = source.length
  totalLinesWidth = ( '' + totalLines ).length
  
  if compile is true
    compileSource source.join '\n'

  # Find the cursor where we are typing and scroll generated code there
  cursorPosition = $( '#source' )[ 0 ].selectionStart
  
  lineNumbers = []
  for line, i in source
    do ( line ) -> 
      lineIndex = i + 1
      lineIndexWidth = ( lineIndex + '' ).length
      bufferWidth = totalLinesWidth - lineIndexWidth
      buffer = ( ' ' for index in [ 0...bufferWidth ] ).join ''
      lineNumber = buffer + lineIndex + '.'
      
      if line.length > columnsPerLine
        lineCount = parseInt( line.length / columnsPerLine ) + 1
        multiple = [ lineNumber ]
         
        for count in [ 1...lineCount ]
          do ->
            multiple.push ( ( ' ' for index in [ 0...totalLinesWidth ] ).join '' )
              
        for ln in multiple
          do ( ln ) ->
            lineNumbers.push ln
      else
        lineNumbers.push lineNumber
        
  lineNumbers = lineNumbers.join '\n'
  $( '#source_line_numbers' )[ 0 ].value = lineNumbers

  # Scroll compiled code section
  compiledPosition = findVariableAssignment cursorPosition, originalSource
  
  # -5 is due to textarea left padding of 5px
  columnsPerCompiledLine = ( $( '#results' )[ 0 ].clientWidth - 5 ) / fontWidth
  columnsPerCompiledLine = parseInt columnsPerCompiledLine

  # Find which line the function declaration we are looking for is at
  compiledCode = $( '#results' ).text()
  compiledCode = compiledCode.split '\n'
  lineNumber = 0
  counterPosition = 0
  for line, i in compiledCode
    #if line.length > columnsPerCompiledLine
    #  lineCount = parseInt( line.length / columnsPerCompiledLine ) + 1
    #  lineNumber += lineCount
    #else 
    lineNumber += 1
    counterPosition += line.length
    if counterPosition > compiledPosition
      break
  
  # lineNumber has the number of lines we need to scroll the compiled code
  $( '#results' ).scrollTop ( lineNumber * fontHeight )  

# Setup the compilation function, to run when you stop typing.
compileSource = ( source ) ->
  window.compiledJS = ''
  try
    window.compiledJS = CoffeeScript.compile source, bare: on
    el = $( '#results' )[ 0 ]
    if el.innerText
      el.innerText = window.compiledJS
    else
      $( el ).text window.compiledJS
    $( '#error' ).hide()
  catch error
    capture = error.message.match /error on line (\d+)\:/i
    errorLine = capture[ 1 ]
    source = source.split '\n'
    # remember that errorLine starts with 1
    # determine the start of error selection
    sourcePriorToError = for index in [ 0...( errorLine - 1 ) ]
      source[ index ]

    sourcePriorToError = sourcePriorToError.join '\n'
    selectionStart = sourcePriorToError.length

    selectionEnd = selectionStart + source[ errorLine - 1 ].length

    #setSelectionRange $( '#source' )[ 0 ], selectionStart, selectionEnd
    
    $( '#error' ).text( error.message ).show()

# Listen for keypresses and recompile.
$( '#source' ).keyup -> lineNumbersAndCompileSource()

# Eval the compiled js.
# TODO: see if this is needed...
evalJS = ->
  try
    eval window.compiledJS
  catch error then alert error

# Load the console with a string of CoffeeScript.
window.loadConsole = ( coffee ) ->
  $( '#source' ).val coffee
  lineNumbersAndCompileSource()
  false
  
# Add drag and drop functionality to the console
window.handleFileSelect = ( evt ) ->
  evt.stopPropagation()
  evt.preventDefault()

  files = evt.originalEvent.dataTransfer.files
  
  reader = new FileReader()

  reader.onload = ( evt ) ->
    window.loadConsole evt.target.result
    false

  file = files[ 0 ]
  $( '.file_name' ).text file.name
  reader.readAsText file

window.handleDragOver = ( evt ) ->
  evt.stopPropagation()
  evt.preventDefault()

$( '#source' )
  .bind( 'dragover', window.handleDragOver, false )
  .bind( 'drop', window.handleFileSelect, false )

$( '.save_button' )
  .click ->
    fileName = $( '.file_name' ).text()
    content = $( '#source' ).val()
    uriContent = "data:application/octet-stream," + encodeURIComponent content
    #document.execCommand 'SaveAs', uriContent, fileName
    newWindow = window.open uriContent, fileName

# Add recalculating line numbers when window is resized
window.onresize = ->
  lineNumbersAndCompileSource false

# By default, compile what's in the source window.
lineNumbersAndCompileSource()