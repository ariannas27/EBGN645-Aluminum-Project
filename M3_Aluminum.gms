*current regions: EU-27, Open-Destinations (OpD), Closed-Destinations(RoW)
set r /EU, OpD, RoW/;
set al /primary, scrap/;


*prices USD/metric ton , qty =  metric tons, currently total aluminum (primary + scrap)
parameter 

*!!!!!!!!!!!!!!!!Prices for Importers need to be higher than the respective exporters!!!!!!!!!!!!!!!!  
pbar(r,al) /EU.primary 2768, EU.scrap 1745, OpD.primary 2784, OpD.scrap 1707, RoW.primary 2419, RoW.scrap 2000/,
*qty supplied aluminum EU, Open-Destinations, and Closed-Destinations
qbar_s(r,al) /EU.primary 1200000, EU.scrap 5601192, OpD.primary 7898000, OpD.scrap 6113480, RoW.primary 63702000, RoW.scrap 30285328/,
*qty demanded aluminum EU, Open-Destinations, and Closed-Destinations
qbar_d(r,al) /EU.primary 7022482, EU.scrap 5000000, OpD.primary 8623521, OpD.scrap 4374909, RoW.primary 57153997, RoW.scrap 32625091/,


*********baseline elasticities*********
*elasticity of supply
e_s(r,al) /EU.primary 0.4, EU.scrap 0.4, OpD.primary 0.4, OpD.scrap 0.4, RoW.primary 0.4, RoW.scrap 0.4/,
*elasticity of demand 
e_d(r,al) /EU.primary -0.21, EU.scrap -0.58, OpD.primary -0.21, OpD.scrap -0.58, RoW.primary -0.21, RoW.scrap -0.58/;

$ontext
*************less elastic (scrap) scenario**************
*elasticity of supply
e_s(r,al) /EU.primary 0.4, EU.scrap 0.2, OpD.primary 0.4, OpD.scrap 0.2, RoW.primary 0.4, RoW.scrap 0.2/,
*elasticity of demand 
e_d(r,al) /EU.primary -0.21, EU.scrap -0.29, OpD.primary -0.21, OpD.scrap -0.29, RoW.primary -0.21, RoW.scrap -0.29/;


*************more elastic (scrap) scenario**************
*elasticity of supply
e_s(r,al) /EU.primary 0.4, EU.scrap 0.61, OpD.primary 0.4, OpD.scrap 0.61, RoW.primary 0.4, RoW.scrap 0.61/,
*elasticity of demand 
e_d(r,al) /EU.primary -0.21, EU.scrap -0.87, OpD.primary -0.21, OpD.scrap -0.87, RoW.primary -0.21, RoW.scrap -0.87/;
$offtext 





*currently based off of Pd = a + b*Qd, Ps = c + d*Qs, where a,b,c,d are parameters
parameter a(r,al),b(r,al),c(r,al),d(r,al); 

b(r,al) = pbar(r,al) / (e_d(r,al) * qbar_d(r,al));
a(r,al) = pbar(r,al) - b(r,al) * qbar_d(r,al);
d(r,al) = pbar(r,al) / (e_s(r,al) * qbar_s(r,al));
c(r,al) = pbar(r,al) - d(r,al) * qbar_s(r,al);

alias(r,rr); 
*t will essentially be the cost of transportation
parameter t(r,rr,al);


t(r,rr,al) = abs(pbar(rr,al) - pbar(r,al)) ; 

*varibales 
positive variable Qd(r,al), Qs(r,al);
**!!!!needs to be for region too!!!!
* variable X(r,al) "exports"; 
variable W "total welfare";

*market clearing conditions 
equation objfn; 


alias(r,rr) ; 
positive variable ship(r,rr,al) ; 


objfn.. W =e=  
   sum((r,al), a(r,al) * Qd(r,al) + b(r,al) * Qd(r,al) *Qd(r,al) /2 
   - c(r,al) * Qs(r,al) - d(r,al) *Qs(r,al) * Qs(r,al) / 2 ) 
   - sum((r,rr,al), t(r,rr,al) * ship(r,rr,al));

equation market_clearing_r(r,al) ; 
market_clearing_r(r,al)..  Qd(r,al) + sum(rr$(not sameas(r,rr)), ship(r,rr,al)) =e= Qs(r,al) + sum(rr$(not sameas(r,rr)), ship(rr,r,al));

model simple /all/; 

solve simple using QCP maximizing W;

*$exit

parameter rep;
parameter shiprep(*,r,rr,al) "shipments by route";

******pre ban results 
rep("BAU", "Qd", r, al) = Qd.l(r,al);
rep("BAU", "Qs", r, al) = Qs.l(r,al);
rep("BAU", "P", r, al)  = market_clearing_r.m(r,al);
*total welfare before the ban
rep("BAU", "W", "total", "total") = W.l;
shiprep("BAU", r, rr, al) = ship.l(r,rr,al);

****************Scrap ban from eu to closed destinations (row)****************
ship.fx('EU','RoW','scrap') = 0;

solve simple using QCP maximizing W;

rep("BAN", "Qd", r, al) = Qd.l(r,al);
rep("BAN", "Qs", r, al) = Qs.l(r,al);
rep("BAN", "P", r, al)  = market_clearing_r.m(r,al);
*total welfare after the ban
rep("BAN", "W", "total", "total") = W.l;
shiprep("BAN", r, rr, al) = ship.l(r,rr,al);

*one gdx with BAU and BAN
execute_unload "simple.gdx";
