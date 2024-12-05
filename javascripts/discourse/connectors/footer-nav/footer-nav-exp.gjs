import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import htmlClass from "discourse/helpers/html-class";
import DiscourseURL from "discourse/lib/url";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import Composer from "discourse/models/composer";
import { SCROLLED_UP, UNSCROLLED } from "discourse/services/scroll-direction";
import dIcon from "discourse-common/helpers/d-icon";
import concatClass from "discourse/helpers/concat-class";
import DMenu from "float-kit/components/d-menu";
import DropdownMenu from "discourse/components/dropdown-menu";
import UserDropdown from "discourse/components/header/user-dropdown/notifications";
import { on } from "@ember/modifier";
import getURL from "discourse-common/lib/get-url";
import { i18n } from "discourse-i18n";

export default class FooterNavExp extends Component {
  @service appEvents;
  @service capabilities;
  @service chatStateManager;
  @service composer;
  @service currentUser;
  @service historyStore;
  @service modal;
  @service router;
  @service scrollDirection;
  @service siteSettings;
  @tracked previousURL;

  constructor() {
    super(...arguments);
    this.router.on("routeDidChange", this, this.#updatePreviousURL);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.router.off("routeDidChange", this, this.#updatePreviousURL);
  }

  #updatePreviousURL() {
    if (!this.currentRouteChat) {
      this.previousURL = this.router.currentURL;
    }
  }

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

  get buttonsLength() {
    let count = 2; // home + hamburger

    if (this.showBackButton) {
      count += 1;
    }

    if (this.showChatButton) {
      count += 1;
    }

    // we only show new topic or share, not both at the same time
    if (this.showNewTopicButton || this.showShareButton) {
      count += 1;
    }

    if (this.showDismissButton) {
      count += 1;
    }

    return count;
  }

  get showBackButton() {
    // or limit to this.currentRouteTopic?
    // return this.capabilities.isAppWebview || this.capabilities.isiOSPWA;
    return true;
  }

  get showChatButton() {
    return this.currentUser?.can_chat;
  }

  get showNewTopicButton() {
    return true;
    //needs updating for chat and PMs
    // return (
    //   this.currentUser?.can_create_topic &&
    //   settings.include_new_topic_button &&
    //   !this.currentRouteTopic &&
    //   !this.currentRouteChat
    // );
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
    if (this.currentRouteChat) {
      const url = getURL(this.previousURL);
      if (url) {
        DiscourseURL.routeTo(url);
      } else {
        DiscourseURL.routeTo(`/`);
      }
    } else {
      DiscourseURL.routeTo(`/`);
    }
  }

  @action
  goChat() {
    // sourced from plugins/chat/assets/javascripts/discourse/components/chat/header/icon.gjs
    if (this.chatStateManager.isFullPageActive) {
      return DiscourseURL.routeTo("/chat");
    }

    DiscourseURL.routeTo(this.chatStateManager.lastKnownChatURL || "/chat");
  }

  @action
  goSearch() {
    return DiscourseURL.routeTo("/search");
  }

  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  @action
  toggleHamburger() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "hamburger",
    });
  }

  @action
  toggleUserMenu() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "user",
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

  // @action
  // goBack(_, event) {
  //   window.history.back();
  //   event.preventDefault();
  // }

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

  get currentRouteChat() {
    return this.router.currentRoute.name.startsWith("chat.");
  }

  get currentRouteTopic() {
    return this.router.currentRoute.name.startsWith("topic.");
  }

  get currentRouteSearch() {
    return this.router.currentRoute.name.startsWith("full-page-search");
  }

  get wrapperClassNames() {
    const classes = ["footer-nav"];

    if (this.isVisible) {
      classes.push("visible");
    }

    classes.push(`buttons-${this.buttonsLength}`);

    return classes.join(" ");
  }

  get chatUnreadIndicator() {
    // JIT import because local-dates isn't necessarily enabled
    const ChatIconUnreadIndicator =
      require("discourse/plugins/chat/discourse/components/chat/header/icon/unread-indicator").default;
    return ChatIconUnreadIndicator;
  }
  <template>
    {{this.setDiscourseHubHeaderBg this.modal.activeModal}}

    {{htmlClass "footer-nav-experiment-present"}}

    {{#if this.capabilities.isIpadOS}}
      {{htmlClass "footer-nav-ipad"}}
    {{else if this.isVisible}}
      {{htmlClass "footer-nav-visible"}}
    {{/if}}

    <div class={{this.wrapperClassNames}}>
      <div class="footer-nav-widget">
        {{!-- {{#if this.showBackButton}}
          <span class="footer-nav__item --back">
            <DButton
              @action={{this.goBack}}
              @icon="chevron-left"
              class={{concatClass
                "btn-flat footer-nav__back"
                (unless this.showBackButton "--disabled")
              }}
              @forwardEvent={{true}}
            />
          </span>
        {{/if}} --}}

        <span class="footer-nav__item --menu">
          <DButton
            @action={{this.toggleHamburger}}
            @icon="bars"
            class="btn-flat footer-nav__hamburger"
          />
        </span>

        <span class="footer-nav__item --home">
          <DButton
            @action={{this.goHome}}
            @icon="home"
            class="btn-flat footer-nav__home
              {{if this.currentRouteHome 'active'}}"
          />
        </span>

        {{!-- {{#if this.showShareButton}}
          <span class="footer-nav__item --share">
            <DButton
              @action={{this.goShare}}
              @icon="share-from-square"
              class="btn-flat footer-nav__share"
            />
          </span>
        {{/if}} --}}

        <span class="footer-nav__item --new">
          <DMenu
            @identifier="new-menu"
            @title="new"
            @icon="plus"
            @class="btn-transparent footer-nav__new-topic"
            @onRegisterApi={{this.onRegisterApi}}
            @modalForMobile={{true}}
          >
            <:content>
              <DropdownMenu as |dropdown|>

                <dropdown.item>
                  {{!-- <button class="btn btn-transparent">{{dIcon
                      "far-pen-to-square"
                    }}
                    New topic</button> --}}
                  <DButton
                    @label={{themePrefix "mobile_footer.new_topic"}}
                    @action={{this.goNewTopic}}
                    @icon="far-pen-to-square"
                    class="btn-transparent"
                  />
                </dropdown.item>
                <dropdown.item>

                  <button class="btn btn-transparent">{{dIcon "comment"}}
                    New chat</button>
                </dropdown.item>
                <dropdown.item>
                  <button class="btn btn-transparent">{{dIcon "envelope"}}
                    New PM</button>
                </dropdown.item>
              </DropdownMenu>
            </:content>
          </DMenu>
        </span>

        {{#if this.showChatButton}}
          <span class="footer-nav__item --chat">
            <DButton
              @action={{this.goChat}}
              @icon="d-chat"
              class="btn-flat footer-nav__chat
                {{if this.currentRouteChat 'active'}}"
              @title="footer_nav.chat"
            />
            {{this.chatUnreadIndicator}}
          </span>
        {{/if}}
        <span class="footer-nav__item --search">
          <button
            class="btn btn-transparent btn-no-text footer-nav__search
              {{if this.currentRouteSearch 'active'}}"
            {{on "click" this.goSearch}}
          >
            {{dIcon "search"}}

          </button>
        </span>

        {{!-- <span class="footer-nav__item --usermenu">
          <button
            class="btn btn-transparent btn-no-text footer-nav__user-menu"
            {{on "click" this.toggleUserMenu}}
          >
            <UserDropdown {{this.handleFocus}} />
          </button>
        </span> --}}

      </div>
    </div>
  </template>
}
