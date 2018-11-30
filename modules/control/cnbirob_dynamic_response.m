function y = cnbirob_dynamic_response(x, support)

    if isfield(support, 'forcebci') == false
        support.forcebci = [];
    end
        

    NumSamples = length(x);
    y = 0.5*ones(NumSamples, 1);
    
    for sId = 2:NumSamples
        prev_value = y(sId-1);
        curr_prob  = x(sId) + 0.5;
        y(sId) = ctrl_integrator_dynamic(curr_prob, prev_value, support);
    end

end