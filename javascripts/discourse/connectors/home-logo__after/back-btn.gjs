import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { and } from "truth-helpers";
import DButton from "discourse/components/d-button";
import DiscourseURL from "discourse/lib/url";

export default class BackBtn extends Component {
  @service router;
  @service site;
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
    if (this.router.session.topicList?.filter) {
      DiscourseURL.routeTo("/" + this.router.session.topicList.filter);
    } else {
      DiscourseURL.routeTo("/");
    }
    event.preventDefault();
  }

  <template>
    {{#if (and this.isTopicTitleVisible this.site.mobileView)}}
      <DButton
        @action={{this.goBack}}
        @icon="chevron-left"
        @forwardEvent={{true}}
        class="btn-transparent d-header__back"
      />
    {{/if}}
  </template>
}
