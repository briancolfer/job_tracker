module ApplicationHelper
  STATUS_BADGE_CLASSES = {
    "cold_call"         => "bg-gray-100 text-gray-700",
    "applied"           => "bg-blue-100 text-blue-700",
    "phone_screen"      => "bg-yellow-100 text-yellow-700",
    "technical_screen"  => "bg-orange-100 text-orange-700",
    "onsite"            => "bg-purple-100 text-purple-700",
    "offer_received"    => "bg-teal-100 text-teal-700",
    "accepted"          => "bg-green-100 text-green-700",
    "rejected"          => "bg-red-100 text-red-700",
    "withdrawn"         => "bg-slate-100 text-slate-700",
    "ghosted"           => "bg-neutral-100 text-neutral-700"
  }.freeze

  def status_badge_class(status)
    STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-gray-100 text-gray-700")
  end
end
