function example_make_vsc_hvdc_case(matfile, train_U, train_Y, ref_y, official_u, official_y)
%EXAMPLE_MAKE_VSC_HVDC_CASE Freeze a VSC-HVDC Section 2 case into a MAT file.
%
% Example usage after running your Simulink model:
%   example_make_vsc_hvdc_case( ...
%       fullfile(pwd,'data','benchmarks','Section2','vsc_hvdc_case.mat'), ...
%       train_U, train_Y, ref_y, u_deepc, y_deepc)
%
% Required array sizes:
%   train_U    : m x Ttrain
%   train_Y    : p x Ttrain
%   ref_y      : p x Tsim
%   official_u : m x Tsim
%   official_y : p x Tsim

case_data = struct();
case_data.name = 'vsc_hvdc';
case_data.train_U = double(train_U);
case_data.train_Y = double(train_Y);
case_data.ref_y = double(ref_y);
case_data.official_u = double(official_u);
case_data.official_y = double(official_y);
case_data.input_labels = {'u_1','u_2','u_3','u_4'};
case_data.output_labels = {'y_1','y_2','y_3'};

save_section2_case_mat(matfile, case_data);
end
