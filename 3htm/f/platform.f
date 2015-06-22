
\ platform.f for jeforth.3htm, jeforth.3hta, and jeforth.3nw
\ KeyCode test page http://www.asquare.net/javascript/tests/KeyCode.html

s" platform.f"		source-code-header

also forth definitions

: {F5}			( -- boolean ) \ Hotkey handler, Confirm the HTA window refresh
				<js> confirm("Really want to restart?") </jsV> ;
				/// Return a false to stop the hotkey event handler chain.
				/// Must intercept onkeydown event to avoid original function.

: {F2}			( -- false ) \ Hotkey handler, Toggle input box EditMode
				." Input box EditMode = " 
				js> kvm.EditMode=Boolean(kvm.EditMode^true) dup . js: print('\n')
				if   <text> textarea:focus { border: 0px solid; background:#FFE0E0; }</text> \ pink as a warning of edit mode
				else <text> textarea:focus { border: 0px solid; background:#E0E0E0; }</text> \ grey
				then js: styleTextareaFocus.innerHTML=pop()                
				js: jump2endofinputbox.click();inputbox.focus();
				false ;
				/// return a 'false' to stop the hotkey event handler chain.

code {F9}		( -- false ) \ Hotkey handler, Smaller the input box
				var r = inputbox.rows;
				if(r<=4) r-=1; else if(r>8) r-=4; else r-=2;
				inputbox.rows = Math.max(r,1);
				if (!r) $("#inputbox").hide();
				jump2endofinputbox.click();inputbox.focus();
				push(false);
				end-code
				/// return a false to stop the hotkey event handler chain.
				last alias {F6} // ( -- flase ) Hotkey handler, Smaller the input box
								/// Duplicated to recover PowerCam conflict.

code {F10}		( -- false ) \ Hotkey handler, Bigger the input box
				$("#inputbox").show()
				var r = 1 * inputbox.rows;
				if(r<4) r+=1; else if(r>8) r+=4; else r+=2;
				inputbox.rows = Math.max(r,1);
				jump2endofinputbox.click();inputbox.focus();
				push(false);
				end-code
				/// return a false to stop the hotkey event handler chain.
				/// Must intercept onkeydown event to avoid original function.
				last alias {F7} // ( -- flase ) Hotkey handler, Bigger the input box
								/// Duplicated to recover PowerCam conflict.

code {F4}		( -- false ) \ Hotkey handler, copy marked string into inputbox
				var selection = getSelection();
				var start, end, ss;
				if (!selection.isCollapsed) {
					if (selection.anchorNode==selection.focusNode) {
						start = Math.min(selection.anchorOffset,selection.focusOffset);
						end   = Math.max(selection.anchorOffset,selection.focusOffset);
						ss = selection.anchorNode.data.slice(start,end);
					} else {
						if (selection.anchorNode.data){  // 我根據實例亂湊的，搞不懂對的用法。
							start = selection.anchorOffset;
							end   = selection.anchorNode.data.length;
							ss = selection.anchorNode.data.slice(start,end);
						} else {
							// 啟動時 mark "VBScript V5.8 Build:16384" 其中那個 16384 就會出這種情形！
							ss = selection.focusNode.data.slice(0,selection.anchorOffset);
						}
					}
					document.getElementById("inputbox").value += " " + ss;
				}
				jump2endofinputbox.click();inputbox.focus();
				push(false);
				end-code
				/// return a false to stop the hotkey event handler chain.
				/// The selection must be made from start to end.

code {esc}		( -- false ) \ Inputbox keydown handler, clean inputbox
				inputbox.value="";
				jump2endofinputbox.click(); inputbox.focus();
				push(true); // 別的 handler 還可以收得到 Esc key。
				end-code

: history-selector ( -- ) \ Popup command history for selection
				<o> <br><select style="width:800px;padding-left:2px;font-size:16px;"></select></o> ( select )
				<js> 
					tos().size = Math.min(16,kvm.cmdhistory.array.length);
					for (var i=0; i<kvm.cmdhistory.array.length; i++){
						var option = document.createElement("option");
						option.text = kvm.cmdhistory.array[i];
						js: tos().add(option);
					}
					tos().selectedIndex=tos().length-1;
					jump2endofinputbox.click();tos().focus();
					var select = tos().onclick = function(){
						inputbox.value = tos().value;
						execute("removeElement");
						inputbox.focus();
						return (false);
					}
					tos().onkeydown = function(e){
						e = (e) ? e : event; var keycode = (e.keyCode) ? e.keyCode : (e.which) ? e.which : false;
						switch(keycode) {
							case 27: /* Esc  */ execute("removeElement"); inputbox.focus(); break;
							case 38: /* Up   */ tos().selectedIndex = Math.max(0,tos().selectedIndex-1); break;
							case 40: /* Down */ tos().selectedIndex = Math.min(tos().length-1,tos().selectedIndex+1); break;
							case 13: /* Enter*/ setTimeout(select,1); break;
						}
						return (false);
					}
				</js> ;

: {up}			( -- boolean ) \ Inputbox keydown handler, get previous command history.
				<js> event.altKey </jsV> if history-selector false else
				<js> event.ctrlKey </jsV> if js: inputbox.value=kvm.cmdhistory.up()
				false else true then then ;
				/// Alt-Up pops up history-selector menu.
				/// Ctrl-Up/Ctrl-Down recall command line history.
				/// Use Ctrl-M instead of 'Enter' when you want a 'Carriage Return' in none EditMode.

: {down}		( -- boolean ) \ Inputbox keydown handler, get next command history.
				<js> event.ctrlKey </jsV> if js: inputbox.value=kvm.cmdhistory.down();
				false else true then ;
				/// Alt-Up pops up history-selector menu.
				/// Ctrl-Up/Ctrl-Down recall command line history.
				/// Use Ctrl-M instead of 'Enter' when you want a 'Carriage Return' in none EditMode.

: {backSpace}	( -- boolean ) \ Inputbox keydown handler, erase output box when input box is empty
				js> inputbox.focus();inputbox.value if 
					true \ inputbox is not empty still don't do the norm.
				else \ inputbox is empty, clear outputbox bottom up
					js> event==null||event.altKey \ So as to allow calling {backSpace} programmatically	
					if \ erase top down
						js> event==null||event.shiftKey \ So as to allow calling {backSpace} programmatically
						if 30 else 1 then for
							js> event&&event.ctrlKey if
								js> outputbox.firstChild ?dup if removeElement then
							else
								js> outputbox.firstChild ?dup if
									js> tos().nodeName  char BR    =
									js> tos(1).nodeName char #text =
									or if removeElement else drop then
								then
							then
						next
					else \ erase bottom up 
						js> outputbox.lastChild ?dup if
							js> tos().nodeName char BR = if removeElement else drop then
						then				
						js> event==null||event.shiftKey \ So as to allow calling {backSpace} programmatically
						if 30 else 1 then for
							js> event&&event.ctrlKey if
								js> outputbox.lastChild ?dup if removeElement then
							else
								js> outputbox.lastChild ?dup if
									js> tos().nodeName  char BR    =
									js> tos(1).nodeName char #text =
									or if removeElement else drop then
								then
							then
						next
					then	
					false
				then ;
				/// {backSpace} erase only the last <BR> and text node. To erase other node
				/// types, use Ctrl-{backSpace}. To erase faster, use Shift-{backSpace} or
				/// Shift-Ctrl-{backSpace}. To erase top down, use Alt key.

code {Tab} 		( -- ) \ Inputbox auto-complete
				with(this){
					if(index == 0){ // index 初值來自 document.onkeydown event, 這是剛按下 Tab 的線索。
						var a=('h '+inputbox.value+' t').split(/\s+/);
						a.pop(); a.shift();
						this.hint = a.pop()||""; // the partial word to be autocompleted
						this.cmdLine = inputbox.value.slice(0,inputbox.value.lastIndexOf(hint))||"";
						this.candidate = []; 
						if(hint){
							for(var key in wordhash) {
								if(key.toLowerCase().indexOf(hint.toLowerCase())!=-1) candidate.push(key); 
							}
							candidate.push(hint);
						}
					}
					if(hint){
						if(index >= candidate.length) index = 0;
						inputbox.value = cmdLine + candidate[index++];
						push(false); // 吃掉這個 Tab key。
					} else {
						push(true); // 不吃掉這個 Tab key，給別人處理。
					}
				}
				end-code
				last :: index=0

: {ctrl-break}	( -- boolean ) \ Inputbox keydown handler, stop outer loop
				."  {ctrl-break} " stop false ;

: help(word) 	( word -- ) \ Show help messages of a word in a HTML table
				js> typeof(help_words)=='object' if else
						<o> <style id=help_words>
							.help_words table, .help_words td , .help_words th, .help_words caption {
								padding:8px;
								border-collapse: collapse;
								border: 2px solid #F0F0F0;
							}
							.help_words tr {background: #E8E8FF}
							.help_words tr:nth-child(1) {background: #D0D0FF}
						</style></o> drop
				then
				<text>
					<table class=help_words style="width:90%">
					<tr>
					  <td style="width:200px"><b>_name_</b></td><td colspan=4><b>_help_</b>
					  [_type_][_vid_][_immediate_][_compile_]</td>
					</tr>
					_comment_
					</table>
				</text> ( word html )
				js> pop().replace(/_name_/,kvm.plain(tos().name))
				js> pop().replace(/_help_/,kvm.plain(tos().help.match(/^\S+\s*(.*?)\s*$/)[1]))
				js>	pop().replace(/_type_/,kvm.plain(tos().type))
				js>	pop().replace(/_vid_/,kvm.plain(tos().vid))
				( word html ) <js> 
					if (tos(1).comment) {
						push(pop().replace(
							/_comment_/,
							"<tr><td colspan=5>"+kvm.plain(tos().comment)+"</td></tr>"
						))
					} else push(pop().replace(/_comment_/,""))
					if (tos(1).immediate)  
						 push(pop().replace(/_immediate_/,"IMMEDIATE")); 
					else push(pop().replace(/_immediate_/,""));
					if (tos(1).compileonly) 
						 push(pop().replace(/_compile_/,"COMPILE-ONLY")); 
					else push(pop().replace(/_compile_/,""));
				</js> 
				</o> 2drop ;

code (help)		( "pattern" -- )  \ Print help message of screened words
				execute("parser(words,help)"); var option = pop();
				for (var j=0; j<order.length; j++) { // 越後面的 priority 越新
					if(option.v) 
						if (order[j].toLowerCase().indexOf(option.v.toLowerCase()) == -1) continue;
					var voc = "\n--------- " + order[j] +" ("+ Math.max(0,words[order[j]].length-1) + " words) ---------\n";
					// 取得範圍內的 words into word_list
					if(option.sw) push(option.sw); else push(""); 
					push(order[j]); push(option.pattern); execute("(words)");
					var word_list = pop();
					// 印出
					if (word_list.length) print(voc);
					for (var i=0; i<word_list.length; i++) {
						push(word_list[i]); execute('help(word)')
					}
				} 
				end-code
				/// Modified by platform.f for HTML table.
				/// Usage: help ([(-V|-v) pattern][(-t|-T|-n|-N) pattern])|[pattern]
				/// None or one of the vocabulary selector:
				///	  -v for matching partial vocabulary name, case insensitive.
				///	  -V is -v and lock, -V- to unlock.
				/// None or one of the following switches:
				///	  -n matches only name pattern, case insensitive.
				///	  -N matches exact name, case sensitive.
				///   -t matches type pattern, case insensitive.
				///   -T matches exact type, case sensitive.
				/// If none of the aboves is given then pattern matches 
				/// all names, helps and comments.
				/// Example: help -V excel.f -n app
				/// Example: help - (Show all words)

: help			( [<patthern>] -- )  \ Print help message of screened words
                char \n|\r word js> tos().length if (help) else
					drop js> typeof(help3we)=='object' if else
						<o> <style id=help3we>
							.help3we table, .help3we td , .help3we th, .help3we caption {
								padding:8px;
								font-size:18px;
								font-family: cursive;
								border-collapse: collapse;
								border: 2px solid #F0F0F0;
							}
							.help3we tr:nth-child(odd)  {background: #D0D0FF}
							.help3we tr:nth-child(even) {background: #E0E0FF}
							.help3we td {min-width: 200px}
						</style></o> drop
					then
					<o>
						<table class=help3we style="width:80%;">
						<caption><h3>jeforth.3we for HTM, HTA, and Node-webkit basic usages</h3></caption>
						<tr>
						  <td><b>Topic</b></td>
						  <td><b>Descriptions</b> (watch video)</td>
						</tr>
						<tr>
						  <td>Introduction</td>
						  <td>jeforth.3we is an implementation of the Forth programming 
						  language written in JavaScript and runs on HTA, HTM, Node.js, and Node-webkit. 
						  Watch <a href="http://www.camdemy.com/media/19253">video</a>.</td>
						</tr>
						<tr>
						  <td>How to</td>
						  <td><a href="http://www.camdemy.com/media/19254">Run the HTML version online</a>. Click <a href="http://figtaiwan.org/project/jeforth/jeforth.3we-master/index.html">here</a> to run.</td>
						</tr>
						<tr>
						  <td>How to</td>
						  <td><a href="http://www.camdemy.com/media/19255">Run the HTML version on local computer</a></td>
						</tr>
						<tr>
						  <td>How to</td>
						  <td><a href="http://www.camdemy.com/media/19256">Run the HTA version</a></td>
						</tr>
						<tr>
						  <td>How to</td>
						  <td><a href="http://www.camdemy.com/media/19257">Run Node.js and Node-Webkit version</a></td>
						</tr>
						<tr>
						  <td>Hotkey F2</td>
						  <td><a href="http://www.camdemy.com/media/19258">Toggle input box EditMode</a></td>
						</tr>
						<tr>
						  <td>Hotkey F4</td>
						  <td><a href="http://www.camdemy.com/media/19259">Copy marked string to inputbox</a></td>
						</tr>
						<tr>
						  <td>Hotkey F5</td>
						  <td><a href="http://www.camdemy.com/media/19260">Restart the jeforth system</a></td>
						</tr>
						<tr>
						  <td>Hotkey F9/F10</td>
						  <td><a href="http://www.camdemy.com/media/19261">Bigger/Smaller input box</a></td>
						</tr>
						<tr>
						  <td>Hotkey Esc</td>
						  <td><a href="http://www.camdemy.com/media/19262">Clear input box</a></td>
						</tr>
						<tr>
						  <td>Hotkey Tab</td>
						  <td><a href="http://www.camdemy.com/media/19263">Forth word auto-complete</a></td>
						</tr>
						<tr>
						  <td>Hotkey Enter</td>
						  <td><a href="http://www.camdemy.com/media/19264">Jump into the input box</a></td>
						</tr>
						<tr>
						  <td>Hotkey Ctrl-Up/Ctrl-Down</td>
						  <td><a href="http://www.camdemy.com/media/19265">Recall command history</a>
						  Were only Up/Down without the 'Ctrl' key. I found using Up/Down key for editing
						  is more often than to recall the command history. BTW, use Ctrl-M instead of 
						  'Enter' when you want a 'Carriage Return'.
						  </td>
						</tr>
						<tr>
						  <td>Hotkey Alt-Up</td>
						  <td><a href="http://www.camdemy.com/media/19266">List command history</a></td>
						</tr>
						<tr>
						  <td>Hotkey Crtl+/Ctrl-</td>
						  <td><a href="http://www.camdemy.com/media/19267">Zoom in/ Zoom out</a></td>
						</tr>
						<tr>
						  <td>Hotkey Ctrl-Break</td>
						  <td><a href="http://www.camdemy.com/media/19268">Stop all parallel running tasks</a></td>
						</tr>
						<tr>
						  <td>Hotkey BackSpace</td>
						  <td><a href="http://www.camdemy.com/media/19269">Trims the output box</a></td>
						</tr>
						<tr>
						  <td>help [pattern]</td>
						  <td>You are reading me. 'help' is also an useful command, "help -N help" to read more.
						  <a href="http://www.camdemy.com/media/19270">Video: Help is helpful</a>.
						  </td>
						</tr>
						<tr>
						  <td>jsc</td>
						  <td><a href="http://www.camdemy.com/media/19271">JavaScript Console</a></td>
						</tr>
						</table>
					</o> drop
				then ;
				' (help) last :: comment=pop().comment
				/// Example: help (Show basic usages)

<js>
	kvm.cmdhistory = {
		max:   1000, // maximum length of the command history
		index: -1,
		array: [],
		push:
			function (cmd){
				cmd = cmd.replace(/^\s*/gm,''); // remove leading white spaces
				cmd = cmd.replace(/\s*$/gm,'');  // remove tailing white spaces
				if(cmd.search(/\S/)==-1) return; // skip blank lines
				this.array.push(cmd);
				for(var i=this.array.length-2; i>=0; i--)
					if(cmd==this.array[i]) this.array.splice(i,1);
				if (this.array.length > this.max ) this.array.shift();
				this.index = this.array.length;
			},
		up:
			function(){
				var cmd="", indexwas = this.index;
				this.index = Math.max(0, this.index-1);
				if (this.array.length > 0 && this.index >= 0 && this.index < this.array.length){
					cmd = this.array[this.index];
				}
				if (indexwas == this.index) {
					if (kvm.tick('beep')) kvm.beep();
					cmd += "  \\ the end";
				}
				return(cmd);
			},
		down:
			function(){
				var cmd="", indexwas = this.index;
				this.index = Math.min(this.array.length-1, this.index+1);
				if(this.array.length > 0 && this.index >= 0 && this.index < this.array.length){
					cmd = this.array[this.index];
				}
				if (indexwas == this.index) {
					if (kvm.tick('beep')) kvm.beep();
					cmd += "  \\ the end";
				}
				return(cmd);
			},
	};

	$("#inputbox")[0].onkeydown = function(e){
		e = (e) ? e : event; var keycode = (e.keyCode) ? e.keyCode : (e.which) ? e.which : false;
		switch(keycode) {
			case   9: /* Tab  */ if(kvm.tick('{Tab}' )){kvm.execute('{Tab}' );return(kvm.pop());} break;
			case  38: /* Up   */ if(kvm.tick('{up}'  )){kvm.execute('{up}'  );return(kvm.pop());} break;
			case  40: /* Down */ if(kvm.tick('{down}')){kvm.execute('{down}');return(kvm.pop());} break;
		 // case  77: /* M    */ if(kvm.tick('{M}'   )){kvm.execute('{M}'   );return(kvm.pop());} break; // ^m 在 textarea 裡本來就有效，無需處理。
		}
		return (true); // pass down to following handlers
	}

	document.onkeydown = function (e) {
		e = (e) ? e : event; var keycode = (e.keyCode) ? e.keyCode : (e.which) ? e.which : false;
		if(kvm.tick('{Tab}')){if(keycode!=9)kvm.tick('{Tab}').index=0} // 按過別的 key 就重來
		switch(keycode) {
			case 13:
				if (!kvm.EditMode || event.ctrlKey) { // CtrlKeyDown
					kvm.inputbox = inputbox.value; // w/o the '\n' character ($10).
					inputbox.value = ""; // 少了這行，如果壓下 Enter 不放，就會變成重複執行。
					kvm.cmdhistory.push(kvm.inputbox);
					kvm.forthConsoleHandler(kvm.inputbox);
					return(false);
				}
				return(true); // In EditMode
			case  27: /* Esc */ if(kvm.tick('{esc}')){kvm.execute('{esc}');return(kvm.pop());} break;
			case 109: /* -   */ if(kvm.tick('{-}'  )){kvm.execute('{-}'  );return(kvm.pop());} break;
			case 107: /* +   */ if(kvm.tick('{+}'  )){kvm.execute('{+}'  );return(kvm.pop());} break;
			case 112: /* F1  */ if(kvm.tick('{F1}' )){kvm.execute('{F1}' );return(kvm.pop());} break;
			case 113: /* F2  */ if(kvm.tick('{F2}' )){kvm.execute('{F2}' );return(kvm.pop());} break;
			case 114: /* F3  */ if(kvm.tick('{F3}' )){kvm.execute('{F3}' );return(kvm.pop());} break;
			case 115: /* F4  */ if(kvm.tick('{F4}' )){kvm.execute('{F4}' );return(kvm.pop());} break;
			case 116: /* F5  */ if(kvm.tick('{F5}' )){kvm.execute('{F5}' );return(kvm.pop());} break;
			case 117: /* F6  */ if(kvm.tick('{F6}' )){kvm.execute('{F6}' );return(kvm.pop());} break;
			case 118: /* F7  */ if(kvm.tick('{F7}' )){kvm.execute('{F7}' );return(kvm.pop());} break;
			case 119: /* F8  */ if(kvm.tick('{F8}' )){kvm.execute('{F8}' );return(kvm.pop());} break;
			case 120: /* F9  */ if(kvm.tick('{F9}' )){kvm.execute('{F9}' );return(kvm.pop());} break;
			case 121: /* F10 */ if(kvm.tick('{F10}')){kvm.execute('{F10}');return(kvm.pop());} break;
			case 122: /* F11 */ if(kvm.tick('{F11}')){kvm.execute('{F11}');return(kvm.pop());} break;
			case 123: /* F12 */ if(kvm.tick('{F12}')){kvm.execute('{F12}');return(kvm.pop());} break;
			case   3: /* ctrl-break */ if(kvm.tick('{ctrl-break}')){kvm.execute('{ctrl-break}');return(kvm.pop());} break;
			case   8: /* Back space */ if(kvm.tick('{backSpace}' )){kvm.execute('{backSpace}' );return(kvm.pop());} break; // disable the [switch previous page] function
		}
		return (true); // pass down to following handlers
	}
</js>

previous definitions
