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

\ Image buffer data array
: haiku-img.data haiku-img  js> pop().data ;

\ Store byte into the image buffer data array, leaving de decremented index on the stack
: haiku-img.data!-- ( d i -- i-1 ) >r r@ haiku-img.data  js: pop()[pop()]=pop()  r> 1- ;

0 constant cx
0 constant cy

\ Store rgb values into the image buffer data array, leaving de decremented index on the stack
: haiku-img.pixel!-- ( b g r i -- i-4 )
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

/ proto constant holds the xt of the word used to calculate the pixel color
0 constant  proto
' cgreen to proto

: haiku 
    outputcanvas.h outputcanvas.w * 4 * 5 - ( last byte address of the image data array )
    ( x,y loops )
    outputcanvas.h for r@ 1- to cy
      outputcanvas.w for r@ 1- to cx
        ( calc pixel color and store it )
        ( r g b i -- )
        >r proto execute r> haiku-img.pixel!--
    next next drop show-haiku-img ;

: sin ( a -- sin(a) ) js> Math.sin(pop()) ;

outputcanvas.w 0.32 * constant coef-w
outputcanvas.h 0.32 * constant coef-h

: switzerland ( -- r g b )
    255 ( r -- )
    cx [ coef-w literal ] / sin 0.95 >     cy [ coef-h literal ] / sin 0.95 > or
    cx [ coef-w literal ] / sin 0.5  > and cy [ coef-h literal ] / sin 0.5  > and 255 * dup ( r g b -- ) ;

: 4spire cx outputcanvas.w / 23 * sin cy outputcanvas.h / 1 swap - max
  cx outputcanvas.w / over / sin cy outputcanvas.h / 1 swap - rot / sin
  2dup / sin 255 * rot 255 * rot 255 * rot ;

: noise random 256 * int dup dup ;

\ This word loads this file into a new textarea for inspection
: loadsource drop
  js> $('#codebox').length if 
  ( don't load if already exists )
  else
    ( hide the stack view panel temporarily )
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

\ Embed video and demo buttons into the outputbox 
cls
<o>
  <iframe width="560" height="315" src="https://www.youtube.com/embed/XRhSk0YXWoY?start=70" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</o> drop cr
<o>
  <button onclick="kvm.dictate('\' switzerland to proto haiku')">switzerland haiku</button>
  <button onclick="kvm.dictate('\' 4spire to proto haiku')">4spire haiku</button>
  <button onclick="kvm.dictate('\' noise to proto haiku')">noise haiku</button>
  <button onclick="kvm.dictate('loadsource')">See source file</button>
</o> drop cr

