
	\ platform.f for jeforth.3nw 
	\ KeyCode test page http://www.asquare.net/javascript/tests/KeyCode.html

	also forth definitions

	\ Save-Restore Local Storage and pseudo interfaces. 
	\ 3htm/f/platform.f has defined window.storage application functions : .get(), 
	\ .set(), .del(), already. For 3nw, low level basics .all(), .save() and .restore() 
	\ are plateform dependent. storage.all() equals to localStorage itself.

    <js>
		window.storage = {};
		storage.all = function(){return(localStorage)};
		storage.restore = function(pathname){
			// Restore localStorage from the given json file or default localstorage.json
			push(pathname ? pathname : "3nw/localstorage.json");
			execute("readTextFile"); // 只有 synchronous 的 3nw, 3hta 才能在 js code 裡這樣用。
			var ss = pop();
			// if is from 3hta then it's utf-8 with BOM (EF BB BF) that bothers NW.js JSON.parse()
			// ss.charCodeAt(0)==65279 that's utf-8 BOM 
			if (ss.charCodeAt(0)==65279) ss = ss.slice(1); // resolve the utf-8 BOM issue
			var ls = JSON.parse(ss);
			for (var i in ls) localStorage[i] = ls[i];
		}
		storage.save = function(pathname){
			// Save localStorage to the json file or default localstorage.json
			var ls = storage.all(); // entire localStorage object
			push(JSON.stringify(ls)); // entire localStorage string
			push(pathname ? pathname : "3nw/localstorage.json");
			execute("writeTextFile");
		}
	</js>
	
	include 3htm/f/platform.f
	
	: {F5}			( -- boolean ) \ Hotkey handler, Confirm reload the application.
					<js> confirm("Really want to restart?") </jsV> 
					if 
						js: storage.save()
						nw :: reloadIgnoringCache() 
					then false ( stop bubbling ) ;
					/// Return a false to stop the hotkey event handler chain.
					/// Must intercept onkeydown event to avoid original function.

	: {-}			( -- boolean ) \ Inputbox keydown handler, zoom out.
					." {-} "
					js> !event.ctrlKey if true else nw :: zoomLevel-=0.5 false then ;
	: {+}			( -- boolean ) \ Inputbox keydown handler, zoom in.
					." {+} "
					js> !event.ctrlKey if true else nw :: zoomLevel+=0.5 false then ;

	previous definitions
