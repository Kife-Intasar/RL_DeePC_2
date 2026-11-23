function st = get_method_plot_style(mname)
%GET_METHOD_PLOT_STYLE Common plotting style for Section 1 and Section 2

switch lower(mname)
    case 'full_deepc'
        st.Color      = [0.00 0.45 0.74];
        st.LineStyle  = '-';
        st.LineWidth  = 1.4;
        st.Marker     = 'none';
        st.MarkerSize = 6;
        st.DisplayName = 'full DeePC';

    case 'svd_deepc'
        st.Color      = [0.85 0.33 0.10];
        st.LineStyle  = '--';
        st.LineWidth  = 1.4;
        st.Marker     = 'none';
        st.MarkerSize = 6;
        st.DisplayName = 'svd DeePC';

    case 'iv_deepc'
        st.Color      = [0.47 0.67 0.19];
        st.LineStyle  = '-.';
        st.LineWidth  = 1.4;
        st.Marker     = '^';
        st.MarkerSize = 5;
        st.DisplayName = 'IV / CL-SPC';

    case 'gamma_ddpc'
        st.Color      = [0.49 0.18 0.56];
        st.LineStyle  = ':';
        st.LineWidth  = 1.7;
        st.Marker     = 's';
        st.MarkerSize = 5;
        st.DisplayName = '\gamma-DDPC';


    case 'replacement_deepc'
        st.Color      = [0.93 0.69 0.13];
        st.LineStyle  = '-';
        st.LineWidth  = 1.8;
        st.Marker     = 'none';
        st.MarkerSize = 5;
        st.DisplayName = 'Replacement DeePC [17]';

    case 'adding_deepc'
        st.Color      = [0.49 0.18 0.56];
        st.LineStyle  = '--';
        st.LineWidth  = 1.8;
        st.Marker     = 'none';
        st.MarkerSize = 5;
        st.DisplayName = 'Adding DeePC [18]';

    case 'online_reduced_order_deepc'
        st.Color      = [0.00 0.00 0.00];
        st.LineStyle  = '-.';
        st.LineWidth  = 2.0;
        st.Marker     = 'none';
        st.MarkerSize = 5;
        st.DisplayName = 'Selective online RO-DeePC';

    case 'arx_mpc'
        st.Color      = [0.30 0.75 0.93];
        st.LineStyle  = '-';
        st.LineWidth  = 1.2;
        st.Marker     = 'x';
        st.MarkerSize = 5;
        st.DisplayName = 'ARX-MPC';

    case 'fir_mpc'
        st.Color      = [0.64 0.08 0.18];
        st.LineStyle  = '--';
        st.LineWidth  = 1.2;
        st.Marker     = '+';
        st.MarkerSize = 5;
        st.DisplayName = 'FIR-MPC';

    case 'era_mpc'
        st.Color      = [0.25 0.25 0.25];
        st.LineStyle  = '-.';
        st.LineWidth  = 1.2;
        st.Marker     = 'v';
        st.MarkerSize = 5;
        st.DisplayName = 'ERA-MPC';

    case 'proposed_bt_deepc'
        st.Color      = [0.80 0.20 0.20];
        st.LineStyle  = '-';
        st.LineWidth  = 2.0;
        st.Marker     = 'o';
        st.MarkerSize = 5;
        st.DisplayName = 'BT projector-DeePC';

    case 'proposed_bt_reduced_deepc'
        st.Color      = [0.80 0.20 0.20];
        st.LineStyle  = '--';
        st.LineWidth  = 2.0;
        st.Marker     = 'o';
        st.MarkerSize = 5;
        st.DisplayName = 'BT reduced-DeePC';

    case 'proposed_irka_deepc'
        st.Color      = [0.10 0.55 0.10];
        st.LineStyle  = '-';
        st.LineWidth  = 2.0;
        st.Marker     = 'd';
        st.MarkerSize = 5;
        st.DisplayName = 'IRKA projector-DeePC';

    case 'proposed_irka_reduced_deepc'
        st.Color      = [0.10 0.55 0.10];
        st.LineStyle  = '--';
        st.LineWidth  = 2.0;
        st.Marker     = 'd';
        st.MarkerSize = 5;
        st.DisplayName = 'IRKA reduced-DeePC';

    otherwise
        st.Color      = [0.20 0.20 0.20];
        st.LineStyle  = '-';
        st.LineWidth  = 1.2;
        st.Marker     = 'none';
        st.MarkerSize = 6;
        st.DisplayName = strrep(mname,'_',' ');
end
end