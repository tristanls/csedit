# Setup the compilation function, to run when you stop typing.
compileSource = ->
  source = $( '#source' ).val()
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
    $( '#error' ).text( error.message ).show()

# Listen for keypresses and recompile.
$( '#source' ).keyup -> compileSource()

# Eval the compiled js.
# TODO: see if this is needed...
evalJS = ->
  try
    eval window.compiledJS
  catch error then alert error

# Load the console with a string of CoffeeScript.
window.loadConsole = ( coffee ) ->
  $( '#source' ).val coffee
  compileSource()
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

  reader.readAsText files[ 0 ]

window.handleDragOver = ( evt ) ->
  evt.stopPropagation()
  evt.preventDefault()

$( '#source' )
  .bind( 'dragover', window.handleDragOver, false )
  .bind( 'drop', window.handleFileSelect, false )

# By default, compile what's in the source window.
compileSource()