import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";

export default class BackBtn extends Component {
  @service router;
  @service header;

  get isTopicTitleVisible() {
    if (
      (this.currentRouteChat || this.currentRouteTopic) &&
      this.header.topicInfoVisible
    ) {
      return true;
    } else {
      return false;
    }
  }

  get currentRouteChat() {
    return this.router.currentRoute.name.startsWith("chat.");
  }

  get currentRouteTopic() {
    return this.router.currentRoute.name.startsWith("topic.");
  }

  @action
  goBack(_, event) {
    window.history.back();
    event.preventDefault();
  }

  <template>
    {{#if this.isTopicTitleVisible}}
      <DButton
        @action={{this.goBack}}
        @icon="chevron-left"
        class="btn-transparent d-header__back"
        @forwardEvent={{true}}
      />
    {{/if}}
  </template>
}
