import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import htmlClass from "discourse/helpers/html-class";
import DiscourseURL from "discourse/lib/url";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import Composer from "discourse/models/composer";
import { SCROLLED_UP, UNSCROLLED } from "discourse/services/scroll-direction";
import ChatHeaderIconUnreadIndicator from "discourse/plugins/chat/discourse/components/chat/header/icon/unread-indicator";

export default class FooterNavExp extends Component {
  @service appEvents;
  @service capabilities;
  @service scrollDirection;
  @service composer;
  @service modal;
  @service historyStore;
  @service currentUser;
  @service router;
  @service siteSettings;

  _modalOn() {
    postRNWebviewMessage("headerBg", "rgb(0, 0, 0)");
  }

  _modalOff() {
    postRNWebviewMessage(
      "headerBg",
      document.documentElement.style.getPropertyValue("--header_background")
    );
  }

  @action
  setDiscourseHubHeaderBg(hasAnActiveModal) {
    if (!this.capabilities.isAppWebview) {
      return;
    }

    if (hasAnActiveModal) {
      this._modalOn();
    } else {
      this._modalOff();
    }
  }

  get hasChatEnabled() {
    return true;
  }

  get showNewTopicButton() {
    return (
      this.currentUser?.can_create_topic &&
      settings.include_new_topic_button &&
      !this.currentRouteTopic &&
      !this.currentRouteChat
    );
  }

  get showShareButton() {
    return settings.include_new_topic_button && this.currentRouteTopic;
  }

  @action
  dismiss() {
    postRNWebviewMessage("dismiss", true);
  }

  @action
  goHome() {
    if (this.currentRouteHome) {
      document.querySelector(".list-control-toggle-link-trigger").click();
      event.preventDefault();
      return;
    }
    DiscourseURL.routeTo(`/`);
  }

  @action
  goSearch() {
    DiscourseURL.routeTo(`/search`);
  }

  @action
  goChat() {
    DiscourseURL.routeTo(`/chat`);
  }

  @action
  toggleHamburger() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "hamburger",
    });
  }

  @action
  goNewTopic() {
    // If the page has a create-topic button, use it for context sensitive attributes like category
    const createTopicButton = document.querySelector("#create-topic");
    if (createTopicButton) {
      createTopicButton.click();
      return;
    }

    this.composer.open({
      action: Composer.CREATE_TOPIC,
      draftKey: Composer.NEW_TOPIC_KEY,
    });
  }

  get isVisible() {
    return (
      [UNSCROLLED, SCROLLED_UP].includes(
        this.scrollDirection.lastScrollDirection
      ) && !this.composer.isOpen
    );
  }

  get currentRouteHome() {
    const topMenu = this.siteSettings.top_menu.split("|");
    const topMenuRouteNames = topMenu.map((item) => `discovery.${item}`);

    return topMenuRouteNames.includes(this.router.currentRoute.name);
  }

  get currentRouteSearch() {
    return this.router.currentRoute.name === "full-page-search";
  }

  get currentRouteChat() {
    return this.router.currentRoute.name.startsWith("chat.");
  }

  get currentRouteTopic() {
    return this.router.currentRoute.name.startsWith("topic.");
  }

  <template>
    {{this.setDiscourseHubHeaderBg this.modal.activeModal}}

    {{htmlClass "footer-nav-experiment-present"}}

    {{#if this.capabilities.isIpadOS}}
      {{htmlClass "footer-nav-ipad"}}
    {{else if this.isVisible}}
      {{htmlClass "footer-nav-visible"}}
    {{/if}}

    <div class={{concatClass "footer-nav" (if this.isVisible "visible")}}>
      <div class="footer-nav-widget">
        <DButton
          @action={{this.goHome}}
          @icon="home"
          class="btn-flat footer-nav__home
            {{if this.currentRouteHome 'active'}}"
          @title="footer_nav.home"
        />

        <DButton
          @action={{this.goSearch}}
          @icon="search"
          class="btn-flat footer-nav__search
            {{if this.currentRouteSearch 'active'}}"
          @title="footer_nav.search"
        />

        {{#if this.showNewTopicButton}}
          <DButton
            @action={{this.goNewTopic}}
            @icon="plus-circle"
            class="btn-flat footer-nav__new-topic"
            @title="footer_nav.new_topic"
          />
        {{/if}}

        {{#if this.showShareButton}}
          <DButton
            @action={{this.goShare}}
            @icon="share-from-square"
            class="btn-flat footer-nav__share"
            @title="footer_nav.share"
          />
        {{/if}}

        {{#if this.currentUser.can_chat}}
          <span class="footer-nav__chat-wrapper">
            <DButton
              @action={{this.goChat}}
              @icon="d-chat"
              class="btn-flat footer-nav__chat
                {{if this.currentRouteChat 'active'}}"
              @title="footer_nav.chat"
            />
            <ChatHeaderIconUnreadIndicator />
          </span>
        {{/if}}

        <DButton
          @action={{this.toggleHamburger}}
          @icon="bars"
          class="btn-flat footer-nav__hamburger"
          @title="footer_nav.search"
        />

        {{#if this.capabilities.isAppWebview}}
          <DButton
            @action={{this.dismiss}}
            @icon="chevron-down"
            class="btn-flat footer-nav__dismiss"
            @title="footer_nav.dismiss"
          />
        {{/if}}
      </div>
    </div>
  </template>
}
