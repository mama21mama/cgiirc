// position.js: make edge-positioning work on IE
// version 0.3, 18-Apr-2002; requires event.js
// written by Andrew Clover <and\@doxdesk.com>, use freely

var position_h= new Array();
var position_v= new Array();
var position_viewport;
var position_width= 0;
var position_height= 0;
var position_fontsize= 0;
var position_ARBITRARY= 200;

/* Binding. Called on each new element; if the it's <body>, initialise script.
   Check all new elements to see if they need our help, make lists of them */

function position_bind(el) {
  if (!position_viewport) {
    if (!document.body) return;
    // initialisation
    position_viewport= (document.compatMode=='CSS1Compat') ?
      document.documentElement : document.body;
    event_addListener(window, 'resize', position_delayout);
    var em= document.createElement('div');
    em.setAttribute('id', 'position_em');
    em.style.position= 'absolute'; em.style.visibility= 'hidden';
    em.style.fontSize= 'xx-large'; em.style.height= '10em';
    em.style.setExpression('width', 'position_checkFont()');
    document.body.appendChild(em);
  }

  // check for absolute edge-positioned elements (ignore ones from fixed.js!)
  var st= el.style; var cs= el.currentStyle;
  if (cs.position=='absolute' && !st.fixedPWidth) {
    if (cs.left!='auto' && cs.right!='auto') {
      position_h[position_h.length]= el;
      st.position_width= position_ARBITRARY;
      st.width= st.position_width+'px';
      position_delayout();
    }
    if (cs.top!='auto' && cs.bottom!='auto') {
      position_v[position_v.length]= el;
      st.position_height= position_ARBITRARY;
      st.height= st.position_height+'px';
      position_delayout();
  } }
}

function position_checkFont() { position_delayout(); return '1em'; }

/* Layout. For each edge-positioned axis, measure difference between min-edge
   and max-edge positioning, set size to the difference */

// Request re-layout at next available moment
var position_delaying= false;
function position_delayout() {
  if (position_delaying) return;
  position_delaying= true;
  window.setTimeout(position_layout, 0);
}

function position_layout() {
  position_delaying= false;
  var i, el, st, pos, tmp;
  var fs= document.all['position_em'].offsetWidth;
  var newfs= (position_fontsize!=fs && position_fontsize!=0);
  position_fontsize= fs;

  // horizontal axis
  if (position_viewport.clientWidth!=position_width || newfs) {
    position_width= position_viewport.clientWidth;
    for (i= position_h.length; i-->0;) {
      el= position_h[i]; st= el.style; cs= el.currentStyle;
      pos= el.offsetLeft; tmp= cs.left; st.left= 'auto';
      st.position_width+= el.offsetLeft-pos; st.left= tmp;
      if (st.position_width<1) st.position_width= 1;
      st.width= st.position_width+'px';
  } }
  // vertical axis
  if (position_viewport.clientHeight!=position_height || newfs) {
    position_height= position_viewport.clientHeight;
    for (i= position_v.length; i-->0;) {
      el= position_v[i]; st= el.style; cs= el.currentStyle;
      pos= el.offsetTop; tmp= cs.top; st.top= 'auto';
      st.position_height+= el.offsetTop-pos; st.top= tmp;
      if (st.position_height<1) st.position_height= 1;
      st.height= st.position_height+'px';
  } }
}

/* Start. If IE, get event to call us back on every new element */

if (window.clientInformation) {
  event_addBinding('*', position_bind);
}
