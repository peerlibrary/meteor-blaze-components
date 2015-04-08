function ExampleComponent() {
  // return ExampleComponent.__super__.constructor.apply(this, arguments);
}

ExampleComponent.prototype = Object.create(BlazeComponent.prototype);
ExampleComponent.prototype.constructor = ExampleComponent;

(_.extendOwn || _.extend)(ExampleComponent, BlazeComponent);
// We want to override __super__ because _.extend copied __super__ from BlazeComponent.
// (Or at least we should delete it, or not copy it in the first place.
ExampleComponent.__super__ = BlazeComponent.prototype;

// We use ExampleComponentJS here for JavaScript implementation.
ExampleComponent.register('ExampleComponentJS');

ExampleComponent.prototype.template = function () {
  return 'ExampleComponent';
};

ExampleComponent.prototype.onCreated = function () {
  // ExampleComponent.__super__.onCreated.apply(this, arguments);
  this.counter = new ReactiveVar(0);
};

ExampleComponent.prototype.events = function () {
  // return ExampleComponent.__super__.events.apply(this, arguments).concat
  return [{
    'click .increment': this.onClick
  }];
};

ExampleComponent.prototype.onClick = function (event) {
  this.counter.set(this.counter.get() + 1);
};

ExampleComponent.prototype.customHelper = function () {
  if (this.counter.get() > 10) {
    return "Too many times";
  }
  else if (this.counter.get() === 10) {
    return "Just enough";
  }
  else {
    return "Click more";
  }
};
