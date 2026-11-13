// Shared helpers for the Margin app pages.
const CFG = window.MARGIN_CONFIG || {};
const configured = !!(CFG.SUPABASE_URL && CFG.SUPABASE_ANON_KEY && !CFG.SUPABASE_URL.startsWith('YOUR'));
const sb = configured ? window.supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY) : null;

// Tiny DOM builder. Text is always set via textContent/createTextNode, never innerHTML,
// so client-supplied names and notes can't inject markup.
function h(tag, attrs, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (k === 'class') e.className = v;
    else if (k.startsWith('on')) e.addEventListener(k.slice(2), v);
    else if (v !== false && v != null) e.setAttribute(k, v === true ? '' : v);
  }
  for (const c of kids.flat()) if (c != null && c !== false) e.append(c.nodeType ? c : document.createTextNode(c));
  return e;
}
const $ = (s, r = document) => r.querySelector(s);
function setMsg(el, text, err) { el.textContent = text || ''; el.className = 'msg' + (err ? ' err' : ''); }
function setupNotice() {
  return h('div', { class: 'notice' },
    h('h2', {}, 'One setup step left'),
    h('p', {}, 'This app needs a free Supabase project. Create one, run supabase.sql in its SQL Editor, then paste the project URL and anon key into config.js.'));
}
const reviewUrl = token => new URL('review.html?p=' + token, location.href).href;
