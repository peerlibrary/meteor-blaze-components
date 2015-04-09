class ExampleComponent extends BlazeComponent {
  template() {
    return 'ExampleComponent';
  }

  onCreated() {
    this.counter = new ReactiveVar(0);
  }

  events() {
    return [{
      'click .increment': this.onClick
    }];
  }

  onClick(event) {
    this.counter.set(this.counter.get() + 1);
  }

  customHelper() {
    if (this.counter.get() > 10) {
      return "Too many times";
    }
    else if (this.counter.get() === 10) {
      return "Just enough";
    }
    else {
      return "Click more";
    }
  }
}

ExampleComponent.register('ExampleComponentES6');

class OurComponent extends BlazeComponent.getComponent('MyComponent') {
  values() {
    return '>>>' + super.values() + '<<<';
  }
}

OurComponent.register('OurComponentES6');
