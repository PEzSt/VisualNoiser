import assert from "node:assert";
import { QuarterEdge, make_quad_edge, make_triangle, inside_triangle } from "../out/delaunay.js";

describe("QuarterEdge Properties", function() {
    var q1 = make_quad_edge([0,1], [0,0]);
    var q2 = make_quad_edge([0,0], [1,0]);
    var q3 = make_quad_edge([0,1], [1,0]);
    
    // Test wether a closed loop of pointers always loops (Mostly because js)
    it("Cyclical Property", function() {
	var et3 = q1;
	var et4 = q1;
	var et1 = q1.next.next.data;
	var et2 = q1.next.next.next.next.data;

	for (var e = 0; e < 256; e++) { // Arbitrary scale of cycles
	    et3 = q1;
	    et4 = q1;
	    var fuzzy_cycle = Math.ceil(Math.random()*256)*2; // Random cycles of 4
	    for (var i = 0; i < fuzzy_cycle; i++){
		et3 = et3.next;
	    } et3 = et3.data;

	    fuzzy_cycle = Math.ceil(Math.random()*256)*4;
	    for (var i = 0; i < fuzzy_cycle; i++){
		et4 = et4.rot;
	    } et4 = et4.data;

	    assert.equal(q1.data, et3);
	    assert.equal(q1.data, et4);
	}
	
	assert.equal(q1.data, et1);
	assert.equal(q1.data, et2);
	assert.equal(q1.data, et3);
	assert.equal(q1.data, et4);
    });

    // Test wether the pointers work properly when chained
    // (should never fail unless quarter-edges are messed with)
    it("Transitive Property", function() {
	var e1 = new QuarterEdge("data1", undefined, undefined);
	var e2 = new QuarterEdge("data2", undefined, undefined);
	var e3 = new QuarterEdge("data3", undefined, undefined);

	e1.next = e2;
	e2.next = e3;
	e3.next = e1;

	var et1 = e1;
	var et2 = e2;
	var et3 = e3;
	var et4 = e1;

	assert.equal(e2, et1.next);
	assert.equal(e3, et2.next);
	assert.equal(e1, et3.next);

	assert.equal(e3, et1.next.next);
	assert.equal(e1, et2.next.next);
	assert.equal(e2, et3.next.next);
    });

    // Small assertions to ensure correct implementation of primitive operations
    // TODO complete with mathematical properties
    it("Primitive Operations", function () {
	assert.equal(q1, q1.tor().tor().rot.rot);
	assert.equal(q1.rot.sym(), q1.sym().rot);
	assert.equal(q1.rot.sym(), q1.tor());
	assert.equal(q1.sym().rot, q1.tor());
	assert.equal(q1, q1.sym().sym());
    });

    it("Triangle Operations", function () {
	var t = make_triangle([0,1], [0,0], [1,0]);

	inside_triangle(t, [0.5, 0.5]);

	//assert.equal(t, t.next.next);
    });

});
