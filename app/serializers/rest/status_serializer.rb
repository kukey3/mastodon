# frozen_string_literal: true

class REST::StatusSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :in_reply_to_id, :in_reply_to_account_id,
             :sensitive, :spoiler_text, :visibility, :language,
             :uri, :content, :url, :reblogs_count, :favourites_count,
             :enquete

  attribute :favourited, if: :current_user?
  attribute :reblogged, if: :current_user?
  attribute :muted, if: :current_user?
  attribute :pinned, if: :pinnable?

  belongs_to :reblog, serializer: REST::StatusSerializer
  belongs_to :application
  belongs_to :account, serializer: REST::AccountSerializer

  has_many :media_attachments, serializer: REST::MediaAttachmentSerializer
  has_many :mentions
  has_many :tags

  has_many :profile_emojis, serializer: REST::ProfileEmojiSerializer

  def current_user?
    !current_user.nil?
  end

  def uri
    TagManager.instance.uri_for(object)
  end

  def content
    Formatter.instance.format(object)
  end

  def enquete
    return nil if object[:enquete].blank?
    Formatter.instance.format_enquete(object[:enquete])
  end

  def url
    TagManager.instance.url_for(object)
  end

  def favourited
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].favourites_map[object.id] || false
    else
      current_user.account.favourited?(object)
    end
  end

  def reblogged
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].reblogs_map[object.id] || false
    else
      current_user.account.reblogged?(object)
    end
  end

  def muted
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].mutes_map[object.conversation_id] || false
    else
      current_user.account.muting_conversation?(object.conversation)
    end
  end

  def pinned
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].pins_map[object.id] || false
    else
      current_user.account.pinned?(object)
    end
  end

  def pinnable?
    current_user? &&
      current_user.account_id == object.account_id &&
      !object.reblog? &&
      %w(public unlisted).include?(object.visibility)
  end

  class ApplicationSerializer < ActiveModel::Serializer
    attributes :name, :website
  end

  class MentionSerializer < ActiveModel::Serializer
    attributes :id, :username, :url, :acct

    def id
      object.account_id
    end

    def username
      object.account_username
    end

    def url
      TagManager.instance.url_for(object.account)
    end

    def acct
      object.account_acct
    end
  end

  class TagSerializer < ActiveModel::Serializer
    include RoutingHelper

    attributes :name, :url

    def url
      tag_url(object)
    end
  end
end
