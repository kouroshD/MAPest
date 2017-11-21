function [forceplates] = transformForceplatesWrenches (forceplates, ...
                                                       subjectParamsFromData, ...
                                                       filenameTrc)  
% TRANSFORMFORCEPLATEWRENCHES transforms external wrenches estimated from 
% forceplates into human frames
% Inputs:
% - forceplates           : forceplate 1 and 2 wrenches in Cortex frames;
% - subjectParamsFromData : for getting the ankle heights, i.e the origin 
%                           position of the reference frame of both feet
%                           wrt their projection on the ground silhoutte 
%                           (provided in fixtureUW.pdf ).
% Outputs:
% - forceplates  : updated struct containing new fields : human right foot 
%                  external wrench (humanRightFootWrench) and human left 
%                  foot external wrench (humanLeftFootWrench). 
%
% External wrenches are estimated by the forceplates in the frame of the 
% Cortex system that is located at a known position. 
% For the human estimation we need to get from this wrenches but: 
% - multiplied by -1 (as the wrench applied on the human is exactly the 
%   opposite of the one excerted on the forceplate)
% - expressed in the frame of the human link in contact.
%
% This function computes the wrenches that each forceplate exerts on the link 
% in contact thank to the relative information between the human and the 
% forceplate, given by the rawSketch.jpg file. 

%% Preliminary note: 
% The subject performs the task with the shoes on the plates. The ankle
% heigths to be considered are a sum of the real ankle height (coming from 
% subjectParamsFromData) + the fixed height of each shoe = 6.0 cm.
shoeHeight = 0.060; % in m
gravityZero = iDynTree.Vector3();
gravityZero.zero();

%% Extract wrenches and position from forceplate data 
fp1Wrench = forceplates.upsampled.FP1.wrenches';
fp2Wrench = forceplates.upsampled.FP2.wrenches';

%% Transform wrenches from forceplates frames to human frames
% Useful information for these transformation are in:
% - rawSketch.jpg  --> for the rotation between each foot wrt the related 
%                      forceplate;
% - fixtureUW.pdf  --> for the position of the each foot wrt the related
%                      forceplate taht is located at the center of the rear
%                      sensor (assumption: on this point there is a
%                      reference frame oriented as in the foot).

% ---- FP1 --> transform FP1 data from FP1 frame to leftFoot frame
% We want: leftFoot_f_fp1 starting from fp1_f_fp1
leftSole_T_fp1Pos = iDynTree.Position();
fp1SeenFromLeftSole = [0.099; 0.063 ; 0];
leftSole_T_fp1Pos.fromMatlab(fp1SeenFromLeftSole);
leftFoot_T_leftSolePos = iDynTree.Position();
leftSoleSeenFromLeftFoot = [0.0; 0.0; ...
                    subjectParamsFromData.leftFootBoxOrigin(3) - shoeHeight];
leftFoot_T_leftSolePos.fromMatlab(leftSoleSeenFromLeftFoot);
leftSole_R_fp1 = iDynTree.Rotation(); % ==leftFoot_R_fp1
leftSole_R_fp1.fromMatlab ([ 0.0, -1.0,  0.0; ...
                            -1.0,  0.0,  0.0; ...
                             0.0,  0.0, -1.0]);
leftFoot_T_fp1 = iDynTree.Transform(leftSole_R_fp1, ...
             leftFoot_T_leftSolePos + leftSole_T_fp1Pos);

% transform the wrench in the proper frame and change the sign
forceplates.upsampled.FP1.humanLeftFootWrench = ...
              -1*(leftFoot_T_fp1.asAdjointTransformWrench().toMatlab()* ...
              fp1Wrench);

% ---- FP2 --> transform FP2 data from FP2 frame to rightFoot frame
% We want: rightFoot_f_fp2 starting from fp2_f_fp2
rightSole_T_fp2Pos = iDynTree.Position();
fp2SeenFromRightSole = [0.099; -0.064 ; 0];
rightSole_T_fp2Pos.fromMatlab(fp2SeenFromRightSole);
rightFoot_T_rightSolePos = iDynTree.Position();
rightSoleSeenFromRightFoot = [0.0; 0.0; ...
                    subjectParamsFromData.rightFootBoxOrigin(3) - shoeHeight];
rightFoot_T_rightSolePos.fromMatlab(rightSoleSeenFromRightFoot);
rightSole_R_fp2 = iDynTree.Rotation(); % ==rightFoot_R_fp2
rightSole_R_fp2.fromMatlab ([ 0.0, -1.0,  0.0; ...
                             -1.0,  0.0,  0.0; ...
                              0.0,  0.0, -1.0]);
rightFoot_T_fp2 = iDynTree.Transform(rightSole_R_fp2, ...
             rightFoot_T_rightSolePos + rightSole_T_fp2Pos);

% transform the wrench in the proper frame and change the sign
forceplates.upsampled.FP2.humanRightFootWrench = ...
              -1*(rightFoot_T_fp2.asAdjointTransformWrench().toMatlab()* ...
              fp2Wrench);

%% Plot tmp

% ----- FP1
fig = figure();
axes1 = axes('Parent',fig,'FontSize',16);
              box(axes1,'on');
              hold(axes1,'on');
              grid on;
len = length(forceplates.upsampled.FP2.humanRightFootWrench);
              
subplot (231) % comparison forces component x
plot1 = plot(fp1Wrench(1,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP1.humanLeftFootWrench(1,:),'r','lineWidth',1.5);
ylabel('forces','HorizontalAlignment','center',...
       'FontWeight','bold',...
       'FontSize',18,...
       'Interpreter','latex');
xlim([0  len]);
title ('x');
grid on;

subplot (232) % comparison forces component y 
plot1 = plot(fp1Wrench(2,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP1.humanLeftFootWrench(2,:),'r','lineWidth',1.5);
title ('y');
xlim([0  len]);
grid on;

subplot (233) % comparison forces component z
plot1 = plot(fp1Wrench(3,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP1.humanLeftFootWrench(3,:),'r','lineWidth',1.5);
title ('z');
xlim([0  len]);
grid on;

subplot (234) % comparison moment component x 
plot1 = plot(fp1Wrench(4,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP1.humanLeftFootWrench(4,:),'r','lineWidth',1.5);
ylabel('moments','HorizontalAlignment','center',...
       'FontWeight','bold',...
       'FontSize',18,...
       'Interpreter','latex');
xlim([0  len]);
grid on;

subplot (235) % comparison moment component y
plot1 = plot(fp1Wrench(5,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP1.humanLeftFootWrench(5,:),'r','lineWidth',1.5);
xlim([0  len]);
grid on;

subplot (236) % comparison moment component z 
plot1 = plot(fp1Wrench(6,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP1.humanLeftFootWrench(6,:),'r','lineWidth',1.5);
xlim([0  len]);
grid on;

leg = legend([plot1,plot2],{'FP1-frame','LeftFoot-frame'});
set(leg,'Interpreter','latex', ...
        'Position',[0.369020817175207 0.95613614004149 0.303215550427647 0.0305007585806261], ...
       'Orientation','horizontal');
set(leg,'FontSize',13);

% ----- FP2
fig = figure();
axes1 = axes('Parent',fig,'FontSize',16);
              box(axes1,'on');
              hold(axes1,'on');
              grid on;
              
subplot (231) % comparison forces component x
plot1 = plot(fp2Wrench(1,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP2.humanRightFootWrench(1,:),'r','lineWidth',1.5);
ylabel('forces','HorizontalAlignment','center',...
       'FontWeight','bold',...
       'FontSize',18,...
       'Interpreter','latex');
xlim([0  len]);
title ('x');
grid on;

subplot (232) % comparison forces component y 
plot1 = plot(fp2Wrench(2,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP2.humanRightFootWrench(2,:),'r','lineWidth',1.5);
title ('y');
xlim([0  len]);
grid on;

subplot (233) % comparison forces component z
plot1 = plot(fp2Wrench(3,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP2.humanRightFootWrench(3,:),'r','lineWidth',1.5);
title ('z');
xlim([0  len]);
grid on;

subplot (234) % comparison moment component x 
plot1 = plot(fp2Wrench(4,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP2.humanRightFootWrench(4,:),'r','lineWidth',1.5);
ylabel('moments','HorizontalAlignment','center',...
       'FontWeight','bold',...
       'FontSize',18,...
       'Interpreter','latex');
xlim([0  len]);
grid on;

subplot (235) % comparison moment component y
plot1 = plot(fp2Wrench(5,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP2.humanRightFootWrench(5,:),'r','lineWidth',1.5);
xlim([0  len]);
grid on;

subplot (236) % comparison moment component z 
plot1 = plot(fp2Wrench(6,:),'b','lineWidth',1.5);
hold on 
plot2 = plot(forceplates.upsampled.FP2.humanRightFootWrench(6,:),'r','lineWidth',1.5);
xlim([0  len]);
grid on;

leg = legend([plot1,plot2],{'FP2-frame','RightFoot-frame'});
 set(leg,'Interpreter','latex', ...
         'Position',[0.369020817175207 0.95613614004149 0.303215550427647 0.0305007585806261], ...
        'Orientation','horizontal');
set(leg,'FontSize',13);

end
