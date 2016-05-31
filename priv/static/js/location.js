function WebSocketManager(ws){
    this.ws = ws;
    this.handlers = [];
    var self = this;
    this.ws.onmessage = function(evt){
        var evnt = JSON.parse(evt.data)
        for(var h in self.handlers){
            self.handlers[h][1].call(self.handlers[h][0], evnt);
        }
    }
}

WebSocketManager.prototype.add_handler = function(obj, handler){
    this.handlers.push([obj, handler])
}

WebSocketManager.prototype.send = function(message){
    this.ws.send(JSON.stringify(message));
}

function Message(type, data, id){
    this.type = type;
    this.data = data;
    this.id = id;
}

function Location(obj, parent, user_id, websocket){
    this.ackd = false;
    this.data = obj;
    this.ws = websocket;
    this.id = this.data.id;
    this.user_id = user_id;
    this.last = {};
    this.events = [];
    this.dom(parent);
    this.graph();
    this.websocket();
}

Location.prototype.dom = function(parent){
    var elem = "<div class=\"col-sm-6 col-md-6\"> \
            <div class=\"thumbnail\"> \
                <img id=\"stream"+this.id+"\"> \
                <div class=\"caption\"> \
                    <div class=\"messages\" id=\"messages"+this.id+"\"><svg></svg></div> \
                </div> \
            </div> \
        </div>";
    var self = this;
    $(parent).append(elem);
    $("#on"+this.id).click(function(){
        self.on();
    });
    $("#off"+this.id).click(function(){
        self.off();
    });
}

Location.prototype.graph = function(){
    var self = this;
    nv.addGraph(function() {
        self.chart = nv.models.lineChart()
            .margin({left: 70, right: 20})
            .useInteractiveGuideline(true)
            .showLegend(true)
            .showYAxis(true)
            .showXAxis(true);

        self.chart.xAxis     //Chart x-axis settings
            .axisLabel('Time (ms)')
            .tickFormat(function(d) { return d3.time.format('%X')(new Date(d*1000)); });

        self.chart.yAxis     //Chart y-axis settings
            .axisLabel('Total Objects')
            .tickFormat(d3.format('.02f'));

        d3.select('#messages'+self.id+' svg')
            .datum(self.events)
            .call(self.chart);

        nv.utils.windowResize(function() { self.chart.update() });
    });

    this.interval = setInterval(function(){
        self.update_graph();
    }, 500);
}

Location.prototype.websocket = function(){
    this.send("location", this.data.data);
    console.log("Location: "+this.id);
    this.ws.add_handler(this, this.onmessage);
}

Location.prototype.onmessage = function(evnt) {
    if(evnt.id != this.id) return;
    if(!this.ackd){
        this.ackd = true;
        this.stream();
    }
    switch(evnt.type){
        case "stats":
            for(var mp in evnt.value){
                var ts = 0;
                for(var ts in evnt.value[mp]){
                    var ev = evnt.value[mp][ts];
                    var tot = 0;
                    for(var k in ev.data.all){
                        if(ev.data.all[k]) tot+= ev.data.all[k];
                    }
                    if(ev.data.timestamp > ts && tot){
                        this.last[ev.id] = {x: ev.data.timestamp, y: tot};
                        ts = ev.data.timestamp;
                    }
                }
            }
            this.update_graph();
    }
};

Location.prototype.update_graph = function(){
    for(var k in this.last){
        var evs = false;
        for(var e in this.events){
            if(this.events[e].key == k) evs = this.events[e];
        }
        if(!evs){
            evs = {key: k, values: []}
            this.events.push(evs)
        }
        var cp = jQuery.extend({}, this.last[k]);
        cp.x = new Date().getTime()/1000;
        evs.values.push(cp);
        if(evs.values.length > 100) evs.values.shift();
    }
    console.log(this.events);
    d3.select('#messages'+this.id+' svg')
        .datum(this.events)
        .call(this.chart);
}

Location.prototype.send = function(type, data){
    var m = new Message(type, data, this.id);
    this.ws.send(m);
}

Location.prototype.on = function(){
    this.send("light", "on");
}

Location.prototype.off = function(){
    this.send("light", "off");
}

Location.prototype.display_event = function(evnt){
    if(evnt.type == "node_message" || evnt.type == "response") return;
    var messages = document.getElementById("messages"+this.id);
    var len = messages.childNodes.length;
    if(len > this.events.length) messages.removeChild(messages.firstChild);

    var v = evnt.data.all;
    try{
        v = JSON.stringify(v);
    }catch(e){
        v = v;
    }
    var e = document.createElement("div");
    e.innerHTML = evnt.id+": "+v;
    messages.appendChild(e);
    e.style.opacity = 0;
    window.getComputedStyle(e).opacity;
    e.style.opacity = 1;
}

Location.prototype.stream = function(){
    $("#stream"+this.id).attr("src", "/stream?location_id="+this.id+"&user_id="+this.user_id);
}
