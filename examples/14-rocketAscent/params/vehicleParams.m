% vehicle masses
fairingMass = 1700;
payloadMass = 22500;
secondStageMass = 4000 + 111500;
aux.mDry = 22000  + fairingMass + payloadMass + secondStageMass;
aux.mFuel = 410843;

% engine characteristics
aux.Tvac = 8227000;
aux.cvac = 3244;
aux.Ae = 11.039;

% aerodynamic properties
aux.cd = 0.329;
aux.Sref = 10.52;