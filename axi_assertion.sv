
import axi_pkg::*;

module axi_assertion(axi_bus_if bus);

    //---------------------------------------------------------
    // Write Address Must Stay Stable
    //---------------------------------------------------------
    property awaddr_stable;
        @(posedge bus.ACLK)
        disable iff(!bus.ARESETn)
        bus.AWVALID && !bus.AWREADY |=> $stable(bus.AWADDR);
    endproperty

    AWADDR_STABLE:
    assert property(awaddr_stable)
    else
        $error("[ASSERT] AWADDR changed before handshake");

    //---------------------------------------------------------
    // WDATA Must Stay Stable
    //---------------------------------------------------------
    property wdata_stable;
        @(posedge bus.ACLK)
        disable iff(!bus.ARESETn)
        bus.WVALID && !bus.WREADY |=> $stable(bus.WDATA);
    endproperty

    WDATA_STABLE:
    assert property(wdata_stable)
    else
        $error("[ASSERT] WDATA changed before handshake");

    //---------------------------------------------------------
    // WSTRB Must Stay Stable
    //---------------------------------------------------------
    property wstrb_stable;
        @(posedge bus.ACLK)
        disable iff(!bus.ARESETn)
        bus.WVALID && !bus.WREADY |=> $stable(bus.WSTRB);
    endproperty

    WSTRB_STABLE:
    assert property(wstrb_stable)
    else
        $error("[ASSERT] WSTRB changed before handshake");

    //---------------------------------------------------------
    // BVALID Must Remain Asserted Until Accepted
    //---------------------------------------------------------
    property bvalid_hold;
        @(posedge bus.ACLK)
        disable iff(!bus.ARESETn)
        bus.BVALID && !bus.BREADY |=> bus.BVALID;
    endproperty

    BVALID_HOLD:
    assert property(bvalid_hold)
    else
        $error("[ASSERT] BVALID dropped before handshake");

    //---------------------------------------------------------
    // ARADDR Must Stay Stable
    //---------------------------------------------------------
    property araddr_stable;
        @(posedge bus.ACLK)
        disable iff(!bus.ARESETn)
        bus.ARVALID && !bus.ARREADY |=> $stable(bus.ARADDR);
    endproperty

    ARADDR_STABLE:
    assert property(araddr_stable)
    else
        $error("[ASSERT] ARADDR changed before handshake");

    //---------------------------------------------------------
    // RVALID Must Stay Asserted Until Accepted
    //---------------------------------------------------------
    property rvalid_hold;
        @(posedge bus.ACLK)
        disable iff(!bus.ARESETn)
        bus.RVALID && !bus.RREADY |=> bus.RVALID;
    endproperty

    RVALID_HOLD:
    assert property(rvalid_hold)
    else
        $error("[ASSERT] RVALID dropped before handshake");
        
    
    initial 
        $display("-------[0t]assertion started ------------------");
endmodule