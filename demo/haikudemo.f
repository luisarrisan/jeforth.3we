s" haikudemo.f"	source-code-header

code outputcanvas     push(document.getElementById('outputcanvas'))                  end-code
code outputcanvas.ctx push(document.getElementById('outputcanvas').getContext('2d')) end-code
code outputcanvas.w   push(document.getElementById('outputcanvas').width)            end-code
code outputcanvas.h   push(document.getElementById('outputcanvas').height)           end-code

code createImg ( height width ctx -- img )
  push(pop().createImageData(pop(), pop()))
end-code

\ Allocate the image objext
outputcanvas.h outputcanvas.w outputcanvas.ctx  createImg   constant haiku-img

: haiku-img.data \ Image buffer data array
  haiku-img  js> pop().data ;

: haiku-img.data!-- ( d i -- i-1 ) \ Store byte into the image buffer data array, leaving de decremented index on the stack
  >r r@ haiku-img.data  js: pop()[pop()]=pop()  r> 1- ;

0 constant cx
0 constant cy

: haiku-img.pixel!-- ( b g r i -- i-4 ) \ Store rgb values into the image buffer data array, leaving de decremented index on the stack
    cx outputcanvas.w < cy outputcanvas.h < and
    cx 0>= and cy 0>= and if
        ( we are in bounds )

        ( store alpha byte )
        255 swap haiku-img.data!--

        ( store b! g! r! bytes )
        haiku-img.data!-- haiku-img.data!-- haiku-img.data!--

    else ( out of bounds, do nothing )
        4 - nip nip nip
    then ;

: show-haiku-img ( -- ) 0 0 haiku-img outputcanvas.ctx js: pop().putImageData(pop(),pop(),pop()) ;

: cred   255 0 0 ;
: cgreen 0 255 0 ;
: cblue  0 0 255 ;

: proto ( -- r g b ) 0 255 0 ;
// proto word is a placeholder

: haiku ( -- ) \ Draws haiku image and shows it
    outputcanvas.h outputcanvas.w * 4 * 5 - ( last byte address of the image data array )
    ( x,y loops )
    outputcanvas.h for r@ 1- to cy
      outputcanvas.w for r@ 1- to cx
        ( calc pixel color and store it )
        ( r g b i -- )
        >r proto r> haiku-img.pixel!--
    next next drop show-haiku-img ;

: sin ( a -- sin(a) ) js> Math.sin(pop()) ;

: coef-w outputcanvas.w 0.32 * literal ; immediate
// Precalc of width coefficient: saves 1 multiplication for every pixel in switzerland

: coef-h outputcanvas.h 0.32 * literal ; immediate
// Precalc of height coefficient: saves 1 multiplication for every pixel in switzerland

: switzerland ( -- r g b ) \ Switzerland's flag
    255 ( r -- )
    cx coef-w / sin 0.95 >     cy coef-h / sin 0.95 > or
    cx coef-w / sin 0.5  > and cy coef-h / sin 0.5  > and 255 * dup ( r g b -- ) ;

: 4spire cx outputcanvas.w / 23 * sin cy outputcanvas.h / 1 swap - max
  cx outputcanvas.w / over / sin cy outputcanvas.h / 1 swap - rot / sin
  2dup / sin 255 * rot 255 * rot 255 * rot ;

: noise random 256 * int dup dup ;

: loadsource ( -- ) \ This word loads this 'haikudemo.f' file into a new textarea for inspection
  js> $('#codebox').length if 
  \ don't load if already exists
  else
    \ hides the stack view panel temporarily
    js: $('#stackview').hide()
    <text>
    <section id="codebox" class="eb wider">
    <p align="center">haikudemo.f</p>
    <button onclick="$('#codebox').remove();js: $('#stackview').show()">Close</button>
    <textarea wrap="off" class="ebtextarea"></textarea>
    </section>
    </text>
    <js>
    $(pop()).insertBefore('#outputbox');
    $('#codebox>textarea').load('demo/haikudemo.f');
    </js>
  then ;

code .cfa@  ( xt -- cfa ) push(pop().cfa) end-code
// Gets cfa from xt

code .cfa!  ( cfa xt -- ) pop().cfa=pop() end-code
// Puts cfa into xt

: is ( xt -- ) \ Usage:  ' word2 is word1 ->  Replace word1's cfa with word2's cfa. Both words must be colon words.
  .cfa@ ' .cfa! ;

\ Embed video and demo buttons into the outputbox 
cls
<o>
  <iframe width="560" height="315" src="https://www.youtube.com/embed/XRhSk0YXWoY?start=70" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</o> drop cr
<o>
  <button onclick="kvm.dictate('\' switzerland is proto haiku')">switzerland haiku</button>
  <button onclick="kvm.dictate('\' 4spire is proto haiku')">4spire haiku</button>
  <button onclick="kvm.dictate('\' noise is proto haiku')">noise haiku</button>
  <button onclick="kvm.dictate('loadsource')">See source file</button>
</o> drop cr

\ Update the stackview just in case...
js: kvm.stackViewRefresh()
