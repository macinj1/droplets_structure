%% Run analysis

[setting,image,BW,droplet,void,void_topology,eq_radio,CV,~,grain_boundaries,grain_size,inner_angles_distribution,psi] = Droplet_Structure ; 

%% Save the data 

disp(' ')
prompt = "Do you want to save the data? y/n: ";
txt = input(prompt,"s");

if strcmp(txt,'y')

    uisave()

end

clear prompt txt 
