/** Syntax Highlighter 3.0 Adapter Class

This class implements the SourceCodeAdapter abstract class.

This takes the DOM elements that the Syntax Highlighter library creates, and generates the DOM nodes that we're looking for.

This class also does any modifications / hackery necessary to the Syntax Highlighter.  In this case, it implements the font increase and decrease functions

Rules:
- This class requires/assumes the Prototype javascript library
- Assumes existence of SourceCodeAdapter abstract class
**/

var SyntaxHighlighter3p0Adapter = Class.create(SourceCodeAdapter, {
  //Syntax Highlighter generates an table DOM tree.  For this adapter,
  //we pass it the root of that tree...
  initialize: function(root_of_table){
    this.root = $(root_of_table);
    this.font_size = 1;
  },
  //Returns an Enumerable collection of DOM nodes representing the source code lines,
  //in order.
  getSourceNodes: function() {
    return this.root.immediateDescendants().getElementsByClass("code").first().getElementsByClassName("container");
  },
  /**Given some node, traverses upwards until it finds the div element that represents a line of code in SyntaxHighlighter.  This is useful for figuring out what text is currently selected, using window.getSelection().anchorNode / focusNode**/
  getRootFromSelection: function(some_node) {
    if(some_node == null) {
      return null;
    }
    var current_node = some_node;
    while(current_node != null && current_node.tagName != 'div') {
      current_node = current_node.parentNode;
    }
    return current_node;
  },
  getFontSize: function() {
    return this.font_size;
  },
  setFontSize: function(font_size) {
    this.font_size = font_size;
  },
  applyMods: function() {
    //We're going to extend Syntax Highlighters menu, and give it some new
    //commands   
    me = this;
    var original_commands = SyntaxHighlighter.toolbar.items;
    original_commands.list = new Array("BoostCode","ShrinkCode", "help");

    original_commands.BoostCode = {
	  execute: function(highlighter) {
	    var code = $$('#code').first();
	    var font_size = me.getFontSize() + .25;
	    me.setFontSize(font_size);
            code.setStyle({fontSize: font_size + 'em'});
	  }
        };
    original_commands.ShrinkCode = {    
          execute: function(highlighter) {
            var code = $$('#code').first();
            var font_size = me.getFontSize() - .25;
            me.setFontSize(font_size);
            code.setStyle({fontSize: font_size + 'em'});
          }
        };
    
    //Attempt to replace tools menu with these new commands
    //$$('.tools').first().update(dp.sh.Toolbar.Create('code').innerHTML)
  }
});
