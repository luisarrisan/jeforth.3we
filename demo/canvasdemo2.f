s" canvas.f"	source-code-header

: my-canvas s" outputcanvas" getElementById ;
<selftest>	." my-canvas -> " my-canvas . cr </selftest>

code .ctx
    push(pop().getContext('2d'))
end-code
<selftest>	." my-canvas.ctx -> " my-canvas .ctx . cr </selftest>

code .width ( ctx -- width )
    push(pop().width)
end-code
<selftest>	." my-canvas.width -> " my-canvas .width . cr </selftest>

code .height ( ctx -- height )
    push(pop().height)
end-code
<selftest>	." my-canvas.height -> " my-canvas .height . cr </selftest>

code createImg ( height width ctx -- img )
  push(pop().createImageData(pop(), pop()))
end-code

my-canvas .height  my-canvas .width  my-canvas .ctx createImg  constant  my-img
<selftest>	." my-img -> " my-img . cr </selftest>

code .data ( img -- data )
    push(pop().data)
end-code

code .data! ( v i img -- )
    pop().data[pop()]=pop()
end-code

: image.w my-canvas .width ;
: image.h my-canvas .height ;

: image--! ( v i -- i++ ) dup >r my-img .data! r> 1- ;

0 constant cx
0 constant cy

: image! ( b g r i -- i-4 )
    cx image.w < cy image.h < and
    cx 0>= and cy 0>= and if
        ( we are in bounds )
        ( b g r i -- )
        255 swap image--! ( s! )
        image--! image--! image--! ( b! g! r! )
    else ( out of bounds )
        4 - nip nip nip
    then ;

code putImageData ( y x img ctx )
    pop().putImageData(pop(), pop(), pop())
end-code

: show 0 0 my-img my-canvas .ctx putImageData ;

: cred   255 0 0 ;
: cgreen 0 255 0 ;
: cblue  0 0 255 ;

0 constant  proto
' cgreen to proto

: haiku 
    image.h image.w * 4 * 5 - ( size )
    image.h for r@ 1- to cy
      image.w for r@ 1- to cx
        >r proto execute r> image!
        \ cx @ . space cy @ . cr
    next next drop show ;

: sin ( x -- sin x ) js> Math.sin(pop()) ;

: switzerland ( -- r g b )
    255 ( r )
    cx image.w 0.32 * / sin 0.95 >    cy image.h 0.32 * / sin 0.95 > or
    cx image.w 0.32 * / sin 0.5 > and cy image.h 0.32 * / sin 0.5 > and 255 * dup ( g b ) ;

: 4spire cx image.w / 23 * sin cy image.h / 1 swap - max
  cx image.w / over / sin cy image.h / 1 swap - rot / sin
  2dup / sin 255 * rot 255 * rot 255 * rot ;

: rndgray random 256 * int dup dup ;

<selftest>
  ' switzerland to proto haiku ." switzerland haiku" cr 
  ' 4spire to proto haiku ." 4spire haiku" cr
  ' rndgray to proto haiku ." 4spire haiku" cr
</selftest>

