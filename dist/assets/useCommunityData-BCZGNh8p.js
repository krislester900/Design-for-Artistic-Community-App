import{c,r as u,j as y,h as k,s as o,m as r}from"./LoadingScreen-DomOgm0c.js";/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const p=[["path",{d:"M12 7v14",key:"1akyts"}],["path",{d:"M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z",key:"ruj8y"}]],$=c("book-open",p);/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const _=[["path",{d:"M20.2 6 3 11l-.9-2.4c-.3-1.1.3-2.2 1.3-2.5l13.5-4c1.1-.3 2.2.3 2.5 1.3Z",key:"1tn4o7"}],["path",{d:"m6.2 5.3 3.1 3.9",key:"iuk76l"}],["path",{d:"m12.4 3.4 3.1 4",key:"6hsd6n"}],["path",{d:"M3 11h18v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z",key:"ltgou9"}]],j=c("clapperboard",_);/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const f=[["ellipse",{cx:"12",cy:"5",rx:"9",ry:"3",key:"msslwz"}],["path",{d:"M3 5V19A9 3 0 0 0 21 19V5",key:"1wlel7"}],["path",{d:"M3 12A9 3 0 0 0 21 12",key:"mv7ke4"}]],A=c("database",f);/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const b=[["rect",{width:"18",height:"18",x:"3",y:"3",rx:"2",key:"afitv7"}],["path",{d:"M7 3v18",key:"bbkbws"}],["path",{d:"M3 7.5h4",key:"zfgn84"}],["path",{d:"M3 12h18",key:"1i2n21"}],["path",{d:"M3 16.5h4",key:"1230mu"}],["path",{d:"M17 3v18",key:"in4fa5"}],["path",{d:"M17 7.5h4",key:"myr1c1"}],["path",{d:"M17 16.5h4",key:"go4c1d"}]],I=c("film",b);/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const v=[["path",{d:"M7.9 20A9 9 0 1 0 4 16.1L2 22Z",key:"vv11sd"}]],z=c("message-circle",v);/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const w=[["path",{d:"M9 18V5l12-2v13",key:"1jmyc2"}],["circle",{cx:"6",cy:"18",r:"3",key:"fqmcym"}],["circle",{cx:"18",cy:"16",r:"3",key:"1hluhg"}]],V=c("music",w);/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const M=[["path",{d:"M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z",key:"1a8usu"}]],F=c("pen",M);function P({src:s,alt:t,fallbackSrc:a='data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="300"%3E%3Crect fill="%23ddd" width="400" height="300"/%3E%3C/svg%3E',...n}){const[i,l]=u.useState(s);return y.jsx("img",{...n,src:i,alt:t,onError:()=>l(a)})}function x(s){return[...s].sort((t,a)=>t.title.localeCompare(a.title,"fr"))}function S(s){return[...s].sort((t,a)=>a.likes-t.likes)}function C(s){return[...s].sort((t,a)=>a.views-t.views)}function E(s){return[...s].sort((t,a)=>Number(a.trending)-Number(t.trending)||a.replies-t.replies)}function N(s){return[...s].sort((t,a)=>t.label.localeCompare(a.label,"fr"))}function h(){return{categories:x(r.categories),artists:S(r.artists),artworks:C(r.artworks),discussions:E(r.discussions),trends:[...r.trends],events:[...r.events],communityStats:N(r.communityStats)}}async function R(){var s;if(!k||!o)return{source:"mock",data:h()};try{const[t,a,n,i,l,g,d]=await Promise.all([o.from("categories").select("slug, title, short_label, description, image, color, target_section_id").order("sort_order",{ascending:!0}),o.from("artists").select("name, category_slug, role, image, featured_work, likes").order("likes",{ascending:!1}),o.from("artworks").select("image, title, artist_name, category_slug, medium, likes, views, height").order("views",{ascending:!1}),o.from("forum_discussions").select("title, author_name, category_slug, replies, time_label, trending").order("trending",{ascending:!1}).order("replies",{ascending:!1}),o.from("trend_tags").select("tag, count_label, category_slug").order("sort_order",{ascending:!0}),o.from("community_events").select("title, date_label, category_slug").order("sort_order",{ascending:!0}),o.from("community_stats").select("number_label, label").order("sort_order",{ascending:!0})]),m=(s=[t,a,n,i,l,g,d].find(e=>e.error))==null?void 0:s.error;if(m)throw m;return{source:"supabase",data:{categories:(t.data??[]).length>0?(t.data??[]).map(e=>({slug:e.slug,title:e.title,shortLabel:e.short_label,description:e.description,image:e.image,color:e.color,targetSectionId:e.target_section_id})):r.categories,artists:(a.data??[]).map(e=>({name:e.name,category:e.category_slug,role:e.role,image:e.image,featuredWork:e.featured_work,likes:e.likes})),artworks:(n.data??[]).map(e=>({image:e.image,title:e.title,artist:e.artist_name,category:e.category_slug,medium:e.medium,likes:e.likes,views:e.views,height:e.height})),discussions:(i.data??[]).map(e=>({title:e.title,author:e.author_name,category:e.category_slug,replies:e.replies,time:e.time_label,trending:e.trending})),trends:(l.data??[]).map(e=>({tag:e.tag,count:e.count_label,category:e.category_slug})),events:(g.data??[]).map(e=>({title:e.title,date:e.date_label,category:e.category_slug})),communityStats:(d.data??[]).length>0?(d.data??[]).map(e=>({number:e.number_label,label:e.label})):r.communityStats}}}catch(t){return console.error("Supabase unavailable, fallback to mock data:",t),{source:"mock",data:h()}}}function Z(){const[s,t]=u.useState({data:r,source:"mock",isLoading:!0});return u.useEffect(()=>{let a=!0;return R().then(n=>{a&&t({data:n.data,source:n.source,isLoading:!1})}),()=>{a=!1}},[]),s}export{$ as B,j as C,A as D,I as F,P as I,V as M,F as P,z as a,Z as u};
