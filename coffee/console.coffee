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

# Add line numbers to the source editor
# But return source without line numbers for compiling
lineNumbersAndCompileSource = ( compile = true )->
  testStringWidth = $( '#font_test' )[ 0 ].clientWidth
  charsInTest = $( '#font_test' )[ 0 ] 
  fontWidth = testStringWidth / 62
  # -5 is due to textarea left padding of 5px
  columnsPerLine = ( $( '#source' )[ 0 ].clientWidth - 5 ) / fontWidth
  columnsPerLine = parseInt columnsPerLine

  originalSource = $( '#source' ).val()
  if originalSource.length is 0
    $( '.file_name' ).text ''
  source = originalSource.split( '\n' )
  totalLines = source.length
  totalLinesWidth = ( '' + totalLines ).length
  
  if compile is true 
    compileSource source.join '\n'
  
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

# Add recalculating line numbers when window is resized
window.onresize = ->
  lineNumbersAndCompileSource false

# By default, compile what's in the source window.
lineNumbersAndCompileSource()