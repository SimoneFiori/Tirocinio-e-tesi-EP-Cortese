load david0; 
solid = [surface.X(1:20:end)'; surface.Y(1:20:end)'; surface.Z(1:20:end)'];
solid = solid - mean(solid,2)*ones(1,size(solid,2));



rot_solid = R*solid;
plot3(rot_solid(:,1),rot_solid(:,2),rot_solid(:,1),'b.')